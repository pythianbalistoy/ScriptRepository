-- Get the handler_id from a collector name.
select handler_id from agent where name = 'sql_chtransvds01.chssql';

-- View current and available subscriptions
select repo_subs._id, repo_subs.dspr_id, repo_subs.repo_name, repo_subs.description, 
  decode(repo_subs.handler_id, null, 
    'INSERT INTO AVAILCONFIG.dsp_repo_subscription (handler_id, dspr_id, created, updated)
    VALUES ('4802', ' || repo_subs.dspr_id || ', sysdate, sysdate);',
    '-- N/A') register_sql
from (
  select rsub.handler_id, repo.dspr_id, repo.repo_name, repo.description
  from dsp_repo_subscription rsub, dsp_repositories repo
  where rsub.dspr_id = repo.dspr_id
  union
  select null, dspr_id, repo_name, description
  from dsp_repositories repo
  where not exists (
    select 1 
    from dsp_repo_subscription repo_sub 
    where repo.dspr_id = repo_sub.dspr_id and repo_sub.handler_id = 4802
  )
) repo_subs
where (repo_subs.handler_id = 4802 or repo_subs.handler_id is null)
order by repo_subs.handler_id, repo_subs.repo_name;



