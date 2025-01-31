# Task Bounty System

A decentralized task bounty system built on the Stacks blockchain using Clarity smart contracts.

## Features

- Create tasks with STX bounties
- Claim tasks
- Complete tasks and receive bounty
- Cancel tasks (creator only)
- View task details and status

## How it works

1. Task creators can post tasks with STX bounties
2. Workers can claim available tasks
3. Upon completion, workers can mark tasks as complete
4. The bounty is automatically transferred to the worker
5. Task creators can cancel unclaimed tasks

## Contract Functions

- create-task: Create a new task with bounty
- claim-task: Claim an available task
- complete-task: Mark a task as completed and receive bounty
- cancel-task: Cancel a task (creator only)
- get-task: View task details
- get-task-count: Get total number of tasks
