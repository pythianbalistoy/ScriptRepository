
select client, update_query 
from (
    select 'Daily Executable' v_type,
        client,
        cde.script_name,
        to_char(cde.version) current_version,
        to_char(max_version.local_max) max_version,
        best_version.local_max best_version,
        best_version.name approval_state,
        'update client_daily_executable set version = ' || best_version.local_max ||
            ' where client = ''' || client || ''' and script_name = ''' || cde.script_name ||
            ''';' update_query
    from (
        select script_name, name, local_max from (
            select script_name, asi.name, max(version) local_max,  RANK() OVER (PARTITION BY script_name ORDER BY asi.rank ASC) RANK
            from daily_executable_version dev,
                approval_state_id asi
            where dev.approval_state = asi.approval_id
            group by script_name, asi.name, approval_state, asi.rank
            order by script_name, asi.rank
        )
        where rank = 1
    ) best_version, (
        select script_name, max(version) local_max
        from daily_executable_version
        group by script_name
    ) max_version,
    client_daily_executable cde
    where 1=1
        and best_version.script_name = cde.script_name
        and max_version.script_name  = cde.script_name
        and cde.version < best_version.local_max

    union all

    select 'Paging Executable' v_type,
        client,
        cpe.script_name,
        to_char(cpe.version) current_version,
        to_char(max_version.local_max) max_version,
        best_version.local_max best_version,
        best_version.name approval_state,
        'update client_paging_executable set version = ' || best_version.local_max ||
            ' where client = ''' || client || ''' and script_name = ''' || cpe.script_name ||
            ''';' update_query
    from (
        select script_name, name, local_max from (
            select script_name, asi.name, max(version) local_max,  RANK() OVER (PARTITION BY script_name ORDER BY asi.rank ASC) RANK
            from paging_executable_version pev,
                approval_state_id asi
            where pev.approval_state = asi.approval_id
            group by script_name, asi.name, approval_state, asi.rank
            order by script_name, asi.rank
        )
        where rank = 1
    ) best_version, (
        select script_name, max(version) local_max
        from paging_executable_version
        group by script_name
    ) max_version,
    client_paging_executable cpe
    where 1=1
        and best_version.script_name = cpe.script_name
        and max_version.script_name  = cpe.script_name
        and cpe.version < best_version.local_max

    union all

    select 'Paging Query' v_type,
        client,
        cpq.query_name,
        to_char(cpq.version) current_version,
        to_char(max_version.local_max) max_version,
        best_version.local_max best_version,
        best_version.name approval_state,
        'update client_paging_query set version = ' || best_version.local_max ||
            ' where client = ''' || client || ''' and query_name = ''' || cpq.query_name ||
            ''';' update_query
    from (
        select query_name, name, local_max from (
            select query_name, asi.name, max(version) local_max,  RANK() OVER (PARTITION BY query_name ORDER BY asi.rank ASC) RANK
            from paging_query_version pqv,
                approval_state_id asi
            where pqv.approval_state = asi.approval_id
            group by query_name, asi.name, approval_state, asi.rank
            order by query_name, asi.rank
        )
        where rank = 1
    ) best_version, (
        select query_name, max(version) local_max
        from paging_query_version
        group by query_name
    ) max_version,
    client_paging_query cpq
    where 1=1
        and best_version.query_name = cpq.query_name
        and max_version.query_name  = cpq.query_name
        and cpq.version < best_version.local_max

    union all

    select 'File Dist' v_type,
        client_id,
        file_title,
        version,
        latest_version,
        null,
        null,
        decode(version,'NA',
        'insert into filedist_file_distributions (file_title, client_id, version, validated, ' ||
        'who_changed, time_entered) ' ||
        'values ('''||file_title||''', '''|| client_id || ''', '''|| latest_version ||
        ''',1,''presley'',sysdate);'

        , 'update filedist_file_distributions set version = ''' || latest_version ||
            ''' where client_id = ''' || client_id || ''' and file_title = ''' ||
            file_title || ''';') update_query
    from (
        select v.version latest_version ,d.file_title, d.client_id, d.version,d.who_changed,d.time_entered
            from filedist_file_distributions d, filedist_file_versions v
            where v.current_version = 1
                and d.file_title = v.file_title
                and v.version <> d.version
        union
        select v.version latest_version, t.file_title, c.client, 'NA' version, 'template_id='||to_char(c.FILEDIST_TEMPLATE_ID) who_changed, null time_entered
            from clients c, filedist_template_distribs t,filedist_file_versions v
            where t.template_id = c.filedist_template_id
            and (c.client, t.file_title) not in (select client_id, file_title from filedist_file_distributions)
            and v.file_title = t.file_title and v.current_version=1
        union
        select 'NA' latest_version, 'NA' file_title, client client_id, 'LEGACY' version,'team = ' || team who_changed,timestamp time_entered
        from clients where filedist_template_id is null
        order by 3,2
    )
)
where 1=1
    --and client like 'kr52pd2.ta'
    and client in (select client from clients where team = 6)
    and v_type = 'File Dist'

and lower(client)  like '%.fdsql'
--and lower(client) not like '%.prosql'
order by client, script_name;

