from flask import Flask, request, send_file
from moviepy.editor import VideoFileClip, TextClip, CompositeVideoClip
import os
import uuid
import shutil

app = Flask(__name__)

FONT_PATH = os.path.join(os.getcwd(), "Baloo2-Regular.ttf")
OUTPUT_FILENAME = "captioned_output.mp4"

def create_captioned_video(video_path, script_path, output_path):
    clip = VideoFileClip(video_path)
    duration = clip.duration

    with open(script_path, 'r', encoding='utf-8') as f:
        script = f.read().strip()

    words = script.split()
    word_duration = duration / len(words)
    caption_clips = []

    for i, word in enumerate(words):
        start = i * word_duration
        end = start + word_duration

        txt_clip = (
            TextClip(
                word.title(),
                fontsize=60,
                font=FONT_PATH,
                color='white',
                stroke_color='black',
                stroke_width=1
            )
            .set_start(start)
            .set_end(end)
            .set_position('center')
            .resize(lambda t: 1.2 - 0.2 * (t / word_duration))  # Zoom-out effect
        )
        caption_clips.append(txt_clip)

    final = CompositeVideoClip([clip] + caption_clips)
    final.write_videofile(output_path, fps=30, codec="libx264", audio_codec="aac", verbose=False, logger=None)

@app.route('/process', methods=['POST'])
def process_video():
    video = request.files['video']
    script = request.files['script']

    # Save input files
    session_id = str(uuid.uuid4())
    os.makedirs(f"temp/{session_id}", exist_ok=True)
    video_path = f"temp/{session_id}/input.mp4"
    script_path = f"temp/{session_id}/script.txt"
    output_path = f"temp/{session_id}/{OUTPUT_FILENAME}"

    video.save(video_path)
    script.save(script_path)

    try:
        create_captioned_video(video_path, script_path, output_path)
        return send_file(output_path, as_attachment=True)
    except Exception as e:
        return {"error": str(e)}, 500

@app.route('/cleanup')
def cleanup():
    shutil.rmtree("temp", ignore_errors=True)
    return "✅ Temp folder cleared."

if __name__ == '__main__':
    os.makedirs("temp", exist_ok=True)
    app.run(debug=True)
