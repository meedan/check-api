module GenericWorkerHelpers
  def run_later(klass_method, *method_args)
    GenericWorker.perform_async(self.to_s, klass_method, *method_args)
  end

  def run_later_in(time, klass_method, *method_args)
    GenericWorker.perform_in(time, self.to_s, klass_method, *method_args)
  end
end
