module Util
  def mute_io(object = subject, methods = %i[puts print])
    methods.each { |method| allow(object).to receive(method) }
  end
end
