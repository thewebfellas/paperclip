module Paperclip
  # Handles thumbnailing videos that are uploaded.
  class VideoThumbnail

    attr_accessor :file

    def initialize file
      @file = file
      @format = 'jpg'
    end

    # Creates a thumbnail, as specified in +initialize+, +make+s it, and returns the
    # resulting Tempfile.
    def self.make file
      new(file).make
    end

    # Performs the conversion of the +file+ into a thumbnail. Returns the Tempfile
    # that contains the new image.
    def make
      src = @file
      dst = Tempfile.new([@basename, @format].compact.join("."))
      dst.binmode

      command = "-y -itsoffset -4 -i \"#{File.expand_path(src.path)}\" -vcodec mjpeg -vframes 1 -an -f rawvideo \"#{File.expand_path(dst.path)}\""

      begin
        RAILS_DEFAULT_LOGGER.debug("[paperclip] Run ffmpeg")
        success = Paperclip.run("ffmpeg", command)
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the thumbnail for #{@basename}" if @whiny_thumbnails
      end

      RAILS_DEFAULT_LOGGER.debug("[paperclip] Return temp file")
      dst
    end
  end

  # Due to how ImageMagick handles its image format conversion and how Tempfile
  # handles its naming scheme, it is necessary to override how Tempfile makes
  # its names so as to allow for file extensions. Idea taken from the comments
  # on this blog post:
  # http://marsorange.com/archives/of-mogrify-ruby-tempfile-dynamic-class-definitions
  class Tempfile < ::Tempfile
    # Replaces Tempfile's +make_tmpname+ with one that honors file extensions.
    def make_tmpname(basename, n)
      extension = File.extname(basename)
      sprintf("%s,%d,%d%s", File.basename(basename, extension), $$, n, extension)
    end
  end
end
