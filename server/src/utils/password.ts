import { hash, parseOptions, verify } from '@node-rs/argon2';

/**
 * Argon2id password hashing (the library default algorithm). Hashing runs on
 * libuv's thread pool, so it never blocks the event loop.
 */
export class PasswordHasher {
  private dummyHash: Promise<string> | undefined;

  constructor(private readonly params: { memoryCostKib: number; timeCost: number }) {}

  hash(password: string): Promise<string> {
    return hash(password, { memoryCost: this.params.memoryCostKib, timeCost: this.params.timeCost, parallelism: 1 });
  }

  async verify(passwordHash: string, password: string): Promise<boolean> {
    try {
      return await verify(passwordHash, password);
    } catch {
      return false;
    }
  }

  /**
   * Burns the same time as a real verification. Called when the email is
   * unknown so response timing does not reveal which accounts exist.
   */
  async verifyDummy(password: string): Promise<false> {
    this.dummyHash ??= this.hash('dummy-password-for-timing-equalisation');
    await this.verify(await this.dummyHash, password);
    return false;
  }

  /** True when a stored hash uses weaker parameters than the current ones. */
  needsRehash(passwordHash: string): boolean {
    try {
      const options = parseOptions(passwordHash);
      return options.memoryCost < this.params.memoryCostKib || options.timeCost < this.params.timeCost;
    } catch {
      return true;
    }
  }
}
