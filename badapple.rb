require 'open3'

ASCII_CHARS = ' .:-=+*#%@'
WIDTH = 80

def download_video(url)
  puts "Downloading video..."
  Open3.capture3("yt-dlp -f worst -o video.mp4 #{url}")
end

def extract_frame(time)
  Open3.capture3("ffmpeg -ss #{time} -i video.mp4 -vframes 1 -f image2pipe -vcodec ppm -")
end

def rgb_to_ascii(r, g, b)
  brightness = (r + g + b) / 3
  index = (brightness * (ASCII_CHARS.length - 1) / 255).to_i
  ASCII_CHARS[index]
end

def image_to_ascii(image_data)
  lines = image_data.split("\n")
  width = lines[1].split[0].to_i
  height = lines[1].split[1].to_i
  
  pixels = lines[3..-1].join.bytes
  
  scale_h = height / 40
  scale_w = width / WIDTH
  
  output = []
  (0...40).each do |y|
    line = ""
    (0...WIDTH).each do |x|
      px = ((y * scale_h) * width + (x * scale_w)) * 3
      r = pixels[px] || 0
      g = pixels[px + 1] || 0
      b = pixels[px + 2] || 0
      line += rgb_to_ascii(r, g, b)
    end
    output << line
  end
  output.join("\n")
end

url = ARGV[0] || "https://youtu.be/FtutLA63Cp8" 
download_video(url)

duration = Open3.capture3("ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 video.mp4")[0].to_f
fps = 10

(0..duration).step(1.0/fps) do |t|
  stdout, stderr, status = extract_frame(t)
  if status.success?
    print "\033[2J\033[H"
    puts image_to_ascii(stdout)
    sleep(1.0/fps)
  end
end
