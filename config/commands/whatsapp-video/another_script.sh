yt-dlp -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b" \
  --merge-output-format mp4 \
  --recode-video mp4 \
  --postprocessor-args "ffmpeg:-c:v libx264 -profile:v high -level 4.1 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart" \
  "URL"
