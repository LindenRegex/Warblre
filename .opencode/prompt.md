@fix_audit_batch use utils/autoformalization/audit/results/2026-03-24/moonshotai/Kimi-K2.5/results_2026-03-24_18-59-58_filtered.json and the other subagent on you prompt to solve all of those problems 

@implement_proposal implement the following : https://tc39.es/proposal-regex-escaping/

@run_local_audit : create the audit for the modified files, this generation might take hours, this is expected


@filter_audit filter the latest results created

@fix_audit_batch use the latest filter result created and the other subagent on your prompt to solve all of those problems 



I want you to read the latest commit, and add a test file that's the same format as the other (.ml on the test folder) that implement EVERY test on the latest commit, add comment so I know from which file every test are, don't miss any, don't add more, don't test something different



Step 1 : comment writing 
@annotate_rocq implement the comments for the following proposal : proposals/escaping

Step 2 : Code writing 
@implement_from_comments add the code for the following proposal : proposals/escaping

Step 3, generate the audit

Step 4, filter the audit
@filter_audit Check the latest audit created and keep the relevant part 




