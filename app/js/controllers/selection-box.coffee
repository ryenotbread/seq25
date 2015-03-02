select = ->
  {totalTicks, corners, notes} = @getProperties('corners', 'totalTicks', 'notes')
  [lowPitch, highPitch] = corners
  .map (corner)->
    Seq25.Pitch.numberAtScale Math.max(corner.y, 0)
  .sort (a, b)-> a > b

  [firstTick, lastTick] = corners
  .map (corner)->
    Math.round corner.x * totalTicks
  .sort (a, b)-> a > b

  boxed = notes
  .filter (note)->
    {pitchNumber, absoluteTicks, duration} = note.getProperties('pitchNumber', 'absoluteTicks', 'duration')
    (lowPitch  <= pitchNumber <= highPitch) and
    (firstTick <= absoluteTicks + duration) and
    (lastTick  >= absoluteTicks)

  @set('boxed', boxed)

EMPTY_CORNERS =
  [
    {x: 0, y: 0}
    {x: 0, y: 0}
  ]

toggle = (selected, boxed, isAdditive)->
  toggleOne = (item)->
    if selected.contains item
      selected.removeObject item
    else
      selected.pushObject item
    selected

  if isAdditive
    toggleOne note for note in boxed
  else
    selected.setObjects boxed
  selected

Seq25.SelectionBoxController = Ember.Controller.extend
  needs: 'part'
  notes: Em.computed.alias 'controllers.part.notes'
  totalTicks: Em.computed.alias 'controllers.part.totalTicks'

  init: ->
    @setProperties
      _selected: []
      corners: EMPTY_CORNERS
      boxed: []
    @_super()

  selected: Em.computed '_selected.[]', 'boxed.[]', ->
    {_selected, boxed, isAdditive} = @getProperties '_selected', 'boxed', 'isAdditive'
    return _selected unless boxed.length
    selected = _selected.concat []
    toggle selected, boxed, isAdditive

  boxClosed: Em.computed  'corners.@each', ->
    @get('corners').reduce(((sum, corner)-> sum + corner.x + corner.y), 0) == 0

  observeBox: Em.observer 'corners.@each', ->
    select.apply(this) unless @get('boxClosed')

  actions:
    resize: (corners, isAdditive)->
      @setProperties
        corners: corners
        isAdditive: isAdditive

    resized: ->
      {_selected, selected, boxed} = @getProperties '_selected', 'selected', 'boxed'
      _selected.setObjects selected
      boxed.clear()
      @set 'corners', EMPTY_CORNERS

    toggle: (notes, {isAdditive}={})->
      toggle @get('_selected'), notes, isAdditive
