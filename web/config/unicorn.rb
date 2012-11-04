listen ENV['PORT'].to_i
preload_app true

cores = if File.exist?('/proc/cpuinfo')
  File.read('/proc/cpuinfo').scan(/^\s*processor\s*:\s*(\d+)(\s+|$)/).length
else
  2
end
worker_processes [2, cores / 2].max
