class Performance < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Director', 'Conductor', 'Actor', 'Musician', 'Dancer', 'Costume Designer', 'Lighting Designer', 'Choreographer', 'Composer', 'Producer', 'Orchestra', 'Band', 'Choir', 'Other']
    end
  end

end
