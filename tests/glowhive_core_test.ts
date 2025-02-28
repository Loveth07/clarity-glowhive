import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Review validation and editing",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Register user
    let block = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'register-user', [
        types.ascii("reviewer")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Test invalid rating
    let invalidBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'post-review', [
        types.ascii("Test Product"),
        types.uint(6), // Invalid rating
        types.utf8("Great product!")
      ], deployer.address)
    ]);
    
    invalidBlock.receipts[0].result.expectErr(types.uint(103));
    
    // Post valid review
    let validBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'post-review', [
        types.ascii("Test Product"),
        types.uint(5),
        types.utf8("Great product!")
      ], deployer.address)
    ]);
    
    validBlock.receipts[0].result.expectOk();
    
    // Edit review
    let editBlock = chain.mineBlock([
      Tx.contractCall('glowhive_core', 'edit-review', [
        types.uint(0),
        types.utf8("Updated review content"),
        types.uint(4)
      ], deployer.address)
    ]);
    
    editBlock.receipts[0].result.expectOk();
    
    // Verify edited review
    let review = chain.callReadOnlyFn(
      'glowhive_core',
      'get-review',
      [types.uint(0)],
      deployer.address
    );
    
    const reviewData = review.result.expectSome();
    assertEquals(reviewData['rating'], types.uint(4));
    assertEquals(reviewData['content'], "Updated review content");
  }
});

// [Rest of tests remain unchanged...]
