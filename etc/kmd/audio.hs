(deflayer audio
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @aimt @volu @aium @sksp XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @prev @vold @next @skhd XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @aomt @vol0 @aoum XX    _                        XX           XX    XX    XX    XX
  _     _     @aud2             @pp               _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer audio_alt
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     @volU _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     @volD _     _     _     _                               XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    aud2 (layer-toggle audio_alt)
    sksp (cmd-button "audio_speakers")
    skhd (cmd-button "audio_headphones")
    volu (cmd-button "iukmessenger audio --increase 2")
    vold (cmd-button "iukmessenger audio --decrease 2")
    volU (cmd-button "iukmessenger audio --increase 10")
    volD (cmd-button "iukmessenger audio --decrease 10")
    vol0 (cmd-button "iukmessenger audio 10")
    aimt (cmd-button "micmute")
    aium (cmd-button "micunmute")
    aomt (cmd-button "iukmessenger audio --mute")
    aoum (cmd-button "iukmessenger audio --unmute")
    prev PreviousSong
    next NextSong
    pp   PlayPause
)

