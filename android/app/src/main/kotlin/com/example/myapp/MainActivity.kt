package com.example.myapp

import io.flutter.embedding.android.FlutterActivity
import android.media.AudioManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 配置音频模式：允许音乐播放与录音同时进行
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        
        // 设置为通信模式，这样可以同时播放和录音
        // MODE_IN_COMMUNICATION 允许音频输入输出同时工作
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        
        // 在某些设备上还需要启用扬声器
        audioManager.isSpeakerphoneOn = true
    }
}
