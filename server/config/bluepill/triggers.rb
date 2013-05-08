class EmailNotifier < Bluepill::Trigger
  def initialize(process, options={})
    @opts = options
    @hostname = `hostname`
    super
  end

  def notify(transition)
    return nil unless @opts[:notify_on].include?(transition.to_name)

    IO.popen("/usr/sbin/sendmail -t", "w") do |mail|
      mail.puts "To: #{@opts[:email]}"
      mail.puts "Subject: Bluepill alert for #{transition.to_name} on #{@hostname}"
      mail.puts
      mail.puts "#{@opts[:application]}:#{@opts[:process]} on #{@hostname}"
    end
  end
end
