# Task Bounty System

A decentralized task bounty system built on the Stacks blockchain using Clarity smart contracts.

## Features

- Create tasks with STX bounties
- Claim tasks
- Complete tasks and receive bounty
- Cancel unclaimed tasks (creator only)
- View task details and status
- Rate task creators and workers
- View user reputation scores

## How it works

1. Task creators can post tasks with STX bounties
2. Workers can claim available tasks
3. Upon completion, workers can mark tasks as complete
4. The bounty is automatically transferred to the worker
5. Task creators can cancel unclaimed tasks only
6. After completion, both parties can rate each other (1-5 stars)
7. User reputation scores are tracked and publicly viewable

## Contract Functions

- create-task: Create a new task with bounty
- claim-task: Claim an available task
- complete-task: Mark a task as completed and receive bounty (can only be completed once)
- cancel-task: Cancel an unclaimed task (creator only)
- get-task: View task details
- get-task-count: Get total number of tasks
- rate-worker: Rate a worker after task completion (1-5 stars)
- rate-creator: Rate a task creator after task completion (1-5 stars)
- get-user-rating: View a user's average rating and total ratings

## Rating System

The rating system allows:
- Task creators to rate workers (1-5 stars)
- Workers to rate task creators (1-5 stars)
- Viewing of average ratings for any user
- Tracking of total ratings received
- Protection against duplicate ratings
- Rating only after task completion

## Recent Updates

1. Enhanced task completion validation:
   - Added check to prevent multiple completions of the same task
   - New error code (108) for already completed tasks

2. Improved task cancellation rules:
   - Restricted cancellation to unclaimed tasks only
   - Added validation to prevent canceling claimed tasks
   - Ensures bounty refund process is more secure
