BUFFER_TIME = 0.5
Seq25.TransportController = Ember.ObjectController.extend
  needs: ['partsIndex', 'part']

  song: Ember.computed.alias 'model'

  currentPart: (-> @get('controllers.part.name')).property('controllers.part')

  empty: (-> @get('parts').length == 0).property('parts.@each')

  loopDuration: (->
    @get('maxBeatCount') * 60 / +@get('tempo')
  ).property('tempo', 'maxBeatCount')

  currentTime: -> Seq25.audioContext.currentTime
  startedAt: 0
  progress: 0
  scheduledUntil: 0
  isPlaying: false

  beat: Em.computed 'progress', 'tempo', ->
    Math.floor (@get('progress') * @get('tempo')) / 60

  elapsed: ->
    return 0 unless @get 'isPlaying'
    @currentTime() - @get('startedAt')

  play: ->
    @setProperties
      startedAt: @currentTime()
      isPlaying: true
      scheduledUntil: BUFFER_TIME

    {progress, song, scheduledUntil} = @getProperties 'progress', 'song', 'scheduledUntil'

    song.schedule progress, progress, scheduledUntil

    advancePosition = ->
      return unless @get 'isPlaying'
      @set('progress', @elapsed())
      {progress, scheduledUntil} = @getProperties 'progress', 'scheduledUntil'
      if (progress + BUFFER_TIME) > scheduledUntil
        newScheduleEnd = scheduledUntil + BUFFER_TIME
        song.schedule(progress, scheduledUntil, newScheduleEnd)
        @set 'scheduledUntil', newScheduleEnd
      Ember.run.later this, advancePosition, 50

    Ember.run.later this, advancePosition, 50

  stop: ->
    @get('song').stop()
    @setProperties
      scheduledUntil: 0
      startedAt: 0
      progress: 0
      isPlaying: false

  actions:
    play: ->
      if @get('isPlaying') then @stop() else @play()

    addPart: (name) ->
      @get('controllers.partsIndex').send "addPart", name
