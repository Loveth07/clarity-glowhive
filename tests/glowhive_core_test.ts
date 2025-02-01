import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "User registration - success case",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const username = "skincare_lover";
    
    let block = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'register-user', [
        types.ascii(username)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify user info
    let userInfo = chain.callReadOnlyFn(
      'glowhive_core',
      'get-user-info',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    assertEquals(
      userInfo.result.expectSome(),
      `{username: "${username}", reputation: u0, review-count: u0}`
    );
  }
});

Clarinet.test({
  name: "Post review and vote flow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const voter = accounts.get('wallet_1')!;
    
    // Register users
    let setupBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'register-user', [
        types.ascii("reviewer")
      ], deployer.address),
      Tx.contractCall('glowhive_core', 'register-user', [
        types.ascii("voter")
      ], voter.address)
    ]);
    
    setupBlock.receipts.map(receipt => receipt.result.expectOk());
    
    // Post review
    let reviewBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'post-review', [
        types.ascii("Test Product"),
        types.uint(5),
        types.utf8("Great product!")
      ], deployer.address)
    ]);
    
    reviewBlock.receipts[0].result.expectOk();
    const reviewId = reviewBlock.receipts[0].result;
    
    // Vote on review
    let voteBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'vote-review', [
        types.uint(0)
      ], voter.address)
    ]);
    
    voteBlock.receipts[0].result.expectOk();
    
    // Verify review votes
    let review = chain.callReadOnlyFn(
      'glowhive_core',
      'get-review',
      [types.uint(0)],
      deployer.address
    );
    
    const reviewData = review.result.expectSome();
    assertEquals(reviewData['votes'], types.uint(1));
  }
});

Clarinet.test({
  name: "Share routine - success case",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'share-routine', [
        types.ascii("Morning Routine"),
        types.utf8("1. Cleanse\n2. Tone\n3. Moisturize")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify routine
    let routine = chain.callReadOnlyFn(
      'glowhive_core',
      'get-routine',
      [types.uint(0)],
      deployer.address
    );
    
    const routineData = routine.result.expectSome();
    assertEquals(routineData['title'], "Morning Routine");
  }
});

Clarinet.test({
  name: "Create and manage product collection",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Create collection
    let createBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'create-collection', [
        types.ascii("My Favorites"),
        types.utf8("Collection of my holy grail products")
      ], deployer.address)
    ]);
    
    createBlock.receipts[0].result.expectOk();
    
    // Add product to collection
    let addBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'add-to-collection', [
        types.uint(0),
        types.ascii("Test Product")
      ], deployer.address)
    ]);
    
    addBlock.receipts[0].result.expectOk();
    
    // Verify collection
    let collection = chain.callReadOnlyFn(
      'glowhive_core',
      'get-collection',
      [types.uint(0)],
      deployer.address
    );
    
    const collectionData = collection.result.expectSome();
    assertEquals(collectionData['name'], "My Favorites");
    assertEquals(collectionData['products'].length, 1);
  }
});
