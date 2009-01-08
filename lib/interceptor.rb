# Interceptor module
module Interceptor  
  
  # ===========================================================================
  # PUBLIC METHODS
  # ===========================================================================
  
  # Kills process with the given pid (integer) or path to pid file (valid file path).
  # The check to see if process is running is perfomed first.
  #
  # ==== Options
  # * <tt>:signal</tt> - signal to send, default "TERM", see http://www.ruby-doc.org/core-1.9/classes/Process.html#M003009 for more info
  #
  # Returns <tt>true</tt> if process is killed
  #
  # Returns <tt>false</tt> if process is not killed, pid or path to pid file are not valid, process is not running
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
  
  # Checks to see if process with the given pid (integer) or with path to pid file (valid file path) is running using Unix <tt>ps</tt> command
  def process_running?(pid_file_or_pid)
    pid = pidize(pid_file_or_pid)
    (pid and system("ps -p #{pid} | grep #{pid}")) ? true : false
  end        
  
  # Tries to determine process status for the given pid (integer) or for path to pid file (valid file path).
  # If unable to determine status 4 (unable to determine) is returned
  #
  # Return status code as integer
  #
  # === Status codes
  # * 1 - running
  # * 2 - no permission to query
  # * 3 - not running or zombied
  # * 4 - unable to determine status
  #
  # This work only for the user that is owner of the process, for other users use process_running? method
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
  
  # Calls Interceptor#process_status method and returns status as a statement
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
  
  # Returns pid from file set with <tt>pid_file_path</tt>, or <tt>nil</tt> if pid is not valid
  def get_pid_from_pid_file(pid_file_path)
    pid = File.exist?(pid_file_path.to_s) ? File.open(pid_file_path.to_s, "r") { |pid_handle| pid_handle.gets.strip.chomp.to_i } : nil
    valid_pid?(pid) ? pid : nil    
  end
  
  # Deletes pid file
  def delete_pid_file(pid_file_path)
    File.delete(pid_file_path) if File.exists?(pid_file_path)
  end
  
  
  # ===========================================================================
  # PRIVATE METHODS
  # ===========================================================================
  
  private
  
  # Takes pid or file to pid file as argument and returns pid as Integer. If pid is not valid returns <tt>nil</tt> 
  def pidize(pid_file_or_pid)
    pid = get_pid_from_pid_file(pid_file_or_pid) || pid_file_or_pid.to_i
    valid_pid?(pid) ? pid : nil
  end
  
  # Validates pid. Returns <tt>true</tt> or <tt>false</tt>
  def valid_pid?(pid)
    (pid.is_a?(Integer) and pid > 0) ? true : false
  end
  
end
