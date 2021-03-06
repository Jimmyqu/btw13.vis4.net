


$ () ->

    map_cont = $ '#map'
    thumb_cont = $ '#map-thumbs'
    years = ['98','03','08','13']
    year = '13'
    selected = ''
    mode = 'choropleth'
    _cs = null  # global color scale
    _key = null  # key
    _sg = null  # symbol group
    lastKey = null
    keys = ['CDU','SPD','FDP','GRÜNE', 'LINKE']

    partyCols =
        CDU: 'Blues'
        SPD: 'Reds'
        'GRÜNE': 'Greens'
        FDP: 'YlOrBr'
        LINKE: 'PuRd'
        PIRATEN: 'OrRd'
        NPD: 'Grays'
        REP: 'Grays'
        Schill: 'Grays'

    defCol = 'YlGnBu'

    partyLimits =
        CDU: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
        SPD: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
        FDP: [0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.13, 0.15, 0.2]
        'GRÜNE': [0, 0.025, 0.05, 0.08, 0.11, 0.15, 0.18, 0.21]
        'LINKE': [0, 0.005, 0.01, 0.03, 0.05, 0.07, 0.09, 0.11]

    defLimits = [0, 0.0025, 0.005, 0.01, 0.015, 0.03, 0.05, 0.1]


    $.getJSON '/assets/data/all-13.json', (data) ->
        $.get '/assets/svg/wk17-alt.svg', (svg) ->
            $.get '/assets/svg/wk17-small-alt.svg', (svg2) ->

                main = $K.map map_cont

                $.each data, (id, wk) ->
                    wk.id = id

                getVote = (wk, key) ->
                    if wk.v2[key]? and wk.v2[key][year]?
                        wk.v2[key][year] / wk.v2.votes[year]
                    else
                        null

                getColorScale = () ->
                    key = _key
                    values = [0.01]
                    $.each data, (id, wk) ->
                        v = getVote wk, key
                        values.push v if v?
                    base = chroma.hex(Common.partyColors[key] ? '#00d')
                    b = base.hcl()
                    new chroma.ColorScale
                        colors: chroma.brewer[partyCols[key] ? defCol]
                        limits: partyLimits[key] ? defLimits  #chroma.limits(values, 'e', 10)

                wkFill = (d) ->
                    wk = data[d.id] # data[if d.id < 10 then '0'+d.id else d.id]
                    if wk?
                        val = getVote wk, _key
                        if val == 0
                            '#fff'
                        else if val?
                            _cs.getColor(val).hex()
                        else
                            '#ccc'
                    else
                        '#f0f'

                updateLegend = () ->
                    limits = partyLimits[lastKey] ? defLimits
                    lgd = $('.col-legend').html ''
                    for l in limits.slice(1, -1)
                        col = _cs.getColor l+0.001
                        l *= 100
                        l = if l >= 3 or l == 1 or l == 2 then Math.round(l) else l.toFixed(1)
                        d = $('<div>&gt;'+l+'%</div>')
                        d.data 'color', col.hex()
                        d.css
                            background: col
                        if col.hcl()[2] < 0.5
                            d.css 'color', '#fff'
                        lgd.append d
                        d.on 'click', (evt) ->
                            d = $ evt.target
                            col = d.data 'color'
                            for path in main.getLayer('wahlkreise').paths
                                if path.svgPath.attrs.fill == col
                                    path.svgPath.attr 'fill', '#ffd'
                                    path.svgPath.animate
                                        fill: col
                                    , 700

                updateOtherPartySelect = () ->
                    sel = $ '#other-parties'
                    sel.html ''
                    others = []
                    for key of data['77+78'].v2
                        if key != 'votes' and key != 'voters' and key != 'turnout' and key != 'others' and data['77+78'].v2[key][year] > 0
                            others.push key

                    others.sort (a,b) ->
                        data['77+78'].v2[b][year] - data['77+78'].v2[a][year]
                    for key in others
                        sel.append '<option '+(if key == lastKey then 'selected="selected"')+'>'+key+'</option>'
                    return


                barChart = (v2, yr) ->
                    tt = ''
                    bch = 80
                    max = 0
                    keys = ['CDU','SPD','FDP','GRÜNE','LINKE']
                    for key in keys
                        max = Math.max v2[key][yr], max
                    keys.sort (a,b) ->
                        v2[b][yr] - v2[a][yr]
                    tt += '<div class="barchart" style="height:'+bch+'px">'
                    for key in keys
                        v = (v2[key][yr] / v2.votes[yr] * 100).toFixed(1)+'%'
                        bh = (v2[key][yr] / max) * bch
                        tt += '<div class="col" style="margin-top:'+(bch-bh)+'px">'
                        tt += '<div class="bar '+key.replace('Ü','UE')+'" style="height:'+bh+'px">'
                        tt += '<div class="lbl'+(if bh < 20 then ' top' else '')+'">'+v+'</div></div>'
                        tt += '<div class="lbl">'+key+'</div>'
                        tt += '</div>'
                    tt += '</div>'
                    if $.inArray(lastKey, keys) < 0
                        tt += '<div class="tt-other"><b>'+lastKey+':</b> '+(v2[lastKey][yr] / v2.votes[yr] * 100).toFixed(1)+'% ('+v2[lastKey][yr]+')</div>'
                    tt

                updateMaps = (key) ->
                    _key = lastKey = key
                    _cs = getColorScale()
                    $('.key').html key
                    $('span.yr').html (if year < 80 then '20' else '19') + year
                    updateLegend()
                    updateOtherPartySelect()
                    if _sg
                        _sg.remove()
                        _sg = null
                    if mode == 'choropleth'
                        main.getLayer('wahlkreise')
                        .style('fill', wkFill)
                        .style('stroke', '#fff')
                        main.getLayer('fg')
                        .tooltips (d) ->
                            '<b>'+d.name + '</b><br />' + barChart(data[d.id].v2, year)
                    else
                        main.getLayer('wahlkreise')
                        .style('fill', '#eee')
                        .style('stroke', '#bbb8b2')
                        main.getLayer('fg').tooltips (d) ->
                            'no'
                        _sg = main.addSymbols
                            data: data
                            filter: (d) ->
                                d.id != '00'
                            type: $K.Bubble
                            attrs: (d) ->
                                fill: wkFill d
                                'fill-opacity': 0.9
                                'stroke-width': 0.5
                            location: (d) ->
                                'wahlkreise.'+d.id
                            radius: (d) ->
                                Math.sqrt(data[d.id].v2.voters[year] / 100000) * 20
                            tooltip: (d) ->
                                '<b>'+d.n+'</b><br />' + barChart(data[d.id].v2, year)

                        Kartograph.dorlingLayout _sg

                    setTimeout () ->
                        $('#map-controls').fadeIn(1000)
                    ,1000

                    $.each keys, (i, key) ->
                        _key = key
                        _cs = getColorScale()
                        map = $('.thumb.'+key).data 'map'
                        map.getLayer('wahlkreise')
                        .style('fill', wkFill)
                        .style('stroke', wkFill)
                        return

                initMaps = () ->
                    main.setMap svg,
                        padding: 10
                    main.addLayer 'wahlkreise'
                        name: 'bg'
                        styles:
                            stroke: '#000'
                            fill: '#ddd'
                            'stroke-linejoin': 'round'
                            'stroke-width': 4
                    main.addLayer 'wahlkreise'
                        key: 'id'
                        styles:
                            stroke: '#fff'
                            'stroke-linejoin': 'round'
                        # tooltips: (d) ->
                        #     d.name + ' ' + d.id

                    labels = (style) ->
                        main.addSymbols
                            type: $K.Label
                            data: Common.CityLabels
                            location: (d) ->
                                [d.lon, d.lat]
                            text: (d) ->
                                d.name
                            style: style

                    labels (d) ->
                        if d.name.length <= 3
                            'opacity:0.6;stroke:#000;fill:#000;stroke-width:3px;stroke-linejoin:round;font-size:11px;font-weight:bold'
                        else
                            'opacity:0.6;stroke:#fff;fill:#fff;stroke-width:3px;stroke-linejoin:round;font-size:11px;'
                    labels (d) ->
                        if d.name.length <= 3
                            'fill:#fff;font-size:11px;font-weight:bold'
                        else
                            'fill:#555;font-size:11px;'

                    main.addLayer 'wahlkreise'
                        name: 'fg'
                        styles:
                            fill: '#fff'
                            opacity: 0

                    window.map = main
                    $.each keys, (i, key) ->
                        t = $('<div class="thumb" />').appendTo thumb_cont
                        map = $K.map t, 190, 170
                        t.addClass key
                        t.data 'map', map
                        map.setMap svg2,
                            padding: 5
                        map.addLayer 'wahlkreise'
                            name: 'bg'
                            styles:
                                fill: '#999'
                                stroke: '#999'
                                'stroke-width': 3
                        mclick = () ->
                            updateMaps this.key
                            setTimeout () ->
                                $.smoothScroll
                                    scrollTarget: 'h1.key'
                                    offset: -20
                            ,200
                        map.addLayer 'wahlkreise'
                            click: mclick.bind
                                key: key
                            styles:
                                cursor: 'pointer'

                        t.append '<label>'+key+'</label>'
                        t.css 'opacity', 0
                        setTimeout () ->
                            t.animate
                                opacity: 1
                        , Math.sqrt(i+1)*200
                        true

                    return

                initUI = () ->
                    $('.map-type .btn').click (evt) ->
                        btn = $ evt.target
                        $('.map-type .btn').removeClass 'btn-primary'
                        btn.addClass 'btn-primary'
                        mode = btn.data 'type'
                        updateMaps lastKey

                    $('#other-parties').change () ->
                        updateMaps $('#other-parties').val()


                initUI()
                initMaps()
                updateMaps 'CDU'


                elsel = Common.ElectionSelector years, 3
                , (active) ->  # click callback
                    if active < 4 # ignore 2013
                        year = years[active]
                        updateMaps lastKey
                        return true
                    return false


