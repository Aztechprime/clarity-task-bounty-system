import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new task with bounty",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('task-bounty', 'create-task', [
                types.uint(1000),
                types.utf8("Test task description")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let taskCount = chain.callReadOnlyFn(
            'task-bounty',
            'get-task-count',
            [],
            deployer.address
        );
        
        assertEquals(taskCount.result.expectOk(), types.uint(1));
    },
});

Clarinet.test({
    name: "Can claim and complete task",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const worker = accounts.get('wallet_1')!;
        
        // Create task
        let block = chain.mineBlock([
            Tx.contractCall('task-bounty', 'create-task', [
                types.uint(1000),
                types.utf8("Test task description")
            ], deployer.address)
        ]);
        
        // Claim task
        let claimBlock = chain.mineBlock([
            Tx.contractCall('task-bounty', 'claim-task', [
                types.uint(1)
            ], worker.address)
        ]);
        
        claimBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Complete task
        let completeBlock = chain.mineBlock([
            Tx.contractCall('task-bounty', 'complete-task', [
                types.uint(1)
            ], worker.address)
        ]);
        
        completeBlock.receipts[0].result.expectOk().expectBool(true);
    },
});
