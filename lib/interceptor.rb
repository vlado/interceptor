module Interceptor  
  
  def kill_process(pid_file_or_pid, options={})
    killed = false
    signal = options[:signal] || 'TERM'
    pid = pidize(pid_file_or_pid)
    if pid and process_running?(pid)
      Process.kill(signal, pid)
      killed = true
    end
    killed
  end
  
  def process_running?(pid_file_or_pid)
    pid = pidize(pid_file_or_pid)
    (pid and system("ps -p #{pid} | grep #{pid}")) ? true : false
  end        
  
  def process_status(pid_file_or_pid)
    status = 4
    if pid = pidize(pid_file_or_pid)
      begin
        Process.kill(0, pid)
        status = 1
      rescue Errno::EPERM
        status = 2
      rescue Errno::ESRCH
        status = 3
      rescue
        status = 4
      end
    end
    status
  end
  
  def process_status_in_words(pid_file_or_pid)
    status = process_status(pid_file_or_pid)
    words = [
      nil,                                      # 0
      "Process is running",                     # 1
      "No permission to query process!",        # 2
      "Process is NOT running",                 # 3
      "Unable to determine status for process"  # 4
    ]
    words[status]
  end
  
  def get_pid_from_pid_file(pid_file_path)
    pid = File.exist?(pid_file_path.to_s) ? File.open(pid_file_path.to_s, "r") { |pid_handle| pid_handle.gets.strip.chomp.to_i } : nil
    valid_pid?(pid) ? pid : nil    
  end
  
  def delete_pid_file(pid_file_path)
    File.delete(pid_file_path) if File.exists?(pid_file_path)
  end
  
  private
  
  def pidize(pid_file_or_pid)
    pid = get_pid_from_pid_file(pid_file_or_pid) || pid_file_or_pid.to_i
    valid_pid?(pid) ? pid : nil
  end
  
  def valid_pid?(pid)
    (pid.is_a?(Integer) and pid > 0) ? true : false
  end
  
end
