module Dryrun
  class Device
    attr_accessor :name, :id

    def initialize(name, id)
      @name = name
      @id = id
    end
  end
end
