# Updated Specs
Users can stake Moca tokens to accumulate cumulative weight
Cumulative weight is calculated based on the time delta from startTime.
Users are able to stake before startTime, but can only unstake after startTime.
For some users, we will distribute moca tokens, via stakeBehalf() - essentially, we will stake to their addresses for them. They will only need to unstake, if desired.

There is no penalty for unstaking as there is no lockup period of “stickiness” of any kind. 
