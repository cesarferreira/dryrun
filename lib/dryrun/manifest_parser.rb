require 'oga'

module Dryrun

  class ManifestParser

    attr_accessor :package, :launcher_activity

    def initialize(manifest_file)
      doc = Oga.parse_xml(manifest_file)

      @package = get_package(doc)
      @launcher_activity = get_launcher_activity(doc)
    end

    def get_package(doc)
      doc.xpath('//manifest').attr('package').first.value
    end

    def get_launcher_activity(doc)
      activities = doc.css('activity')
      activities.each do |child|
        intent_filter = child.css('intent-filter')

        if !intent_filter.nil? && !intent_filter.empty?
          return child.attr('android:name').value
        end
      end
      false
    end

  end
end
