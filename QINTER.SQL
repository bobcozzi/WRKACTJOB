
SELECT job_name, 
       subsystem,
       authorization_name AS CUR_USRPRF,
       REGEXP_SUBSTR(JOB_NAME, '([^\/]+$)') AS JOB_NAME_SHORT,
       REGEXP_SUBSTR(JOB_NAME, '\d+(?=\/)') AS JOB_NUMBER,
       REGEXP_SUBSTR(JOB_NAME, '(?<=\/).+?(?=\/)') AS JOB_USER,
       JOB_TYPE,
       RTRIM(function_type) CONCAT '-' CONCAT "FUNCTION" AS "Function",
       CAST(CPU_TIME AS DEC(9, 0)) as CPU_TIME,
       ELAPSED_CPU_PERCENTAGE,
       TOTAL_DISK_IO_COUNT,
       S.SPLFILES,
       OUTPUT_QUEUE AS OUTQ,
       job_status AS "STS",
       JOB_ACTIVE_TIME AS "Start Time",
       LR.LASTCMD
  FROM TABLE (  -- Subsystem Filter (add, change Subsystem name to alter results)
         qsys2.active_job_info(SUBSYSTEM_LIST_FILTER => 'QINTER')
       ) AJ
       LEFT OUTER JOIN LATERAL ( -- Get last Command that was run (from the joblog)
           SELECT CAST(message_text AS VARCHAR(80)) AS LASTCMD,
                  AJ.job_name AS JOBNAME
             FROM TABLE (
                 qsys2.joblog_info(AJ.JOB_NAME)
               ) jl
             WHERE MESSAGE_TYPE IS NOT DISTINCT FROM 'REQUEST'
                   AND MESSAGE_TEXT NOT LIKE '/*%'
                   AND MESSAGE_TEXT NOT LIKE '%- RETURN %'
             ORDER BY ordinal_position DESC
             LIMIT 1
         ) LR
         ON aj.job_name = LR.jobname,
       LATERAL (  -- Get count of spooled file created by each job
         SELECT COUNT(*) AS SPLFILES
           FROM TABLE (
               SPOOLED_FILE_INFO(job_name => AJ.JOB_NAME)
             ) SP
       ) S; 
