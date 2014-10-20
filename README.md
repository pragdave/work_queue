WorkQueue
=========

** TODO: Add description **


  WorkQueue.start_link (
    WorkerModule,
    args,

    work_source ( enum | fn ),
    worker_count: n | float | :processor_bound | :io_bound,
    report_results_to: fn | module,
    report_progress_to: fn | module,
    report_progress_interval: nnn mS,
  )        

  WorkQueue.start_link(
    SignatureGenerator,
    [ batch ],
    fn -> dir_walker.next end,
    worker_count: 1.5,
    report_results_to: signature_writer,
    report_progress_to: report_function)
    
