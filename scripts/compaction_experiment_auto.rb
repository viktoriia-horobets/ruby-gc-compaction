require_relative './compaction_experiment'

GC.auto_compact = true if GC.respond_to?(:auto_compact=)
ENV['DO_COMPACT'] = '0' # do not call GC.compact manually

load File.join(__dir__, 'compaction_experiment.rb')
