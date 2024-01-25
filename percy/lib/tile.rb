# frozen_string_literal: true

module Percy
  class Tile
    attr_reader :filepath, :status_bar_height, :nav_bar_height, :header_height, :footer_height, :fullscreen, :sha

    def initialize(status_bar_height, nav_bar_height, header_height, footer_height, filepath: nil, sha: nil,
                   fullscreen: false)
      @filepath = filepath
      @status_bar_height = status_bar_height
      @nav_bar_height = nav_bar_height
      @header_height = header_height
      @footer_height = footer_height
      @fullscreen = fullscreen
      @sha = sha
    end

    def to_h
      {
        'filepath' => @filepath,
        'status_bar_height' => @status_bar_height,
        'nav_bar_height' => @nav_bar_height,
        'header_height' => @header_height,
        'footer_height' => @footer_height,
        'fullscreen' => @fullscreen,
        'sha' => @sha
      }
    end
  end
end
