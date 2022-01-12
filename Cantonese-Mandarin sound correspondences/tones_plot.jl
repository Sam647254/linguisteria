function extract_tones(triples)
   # 1. Filter out polyphones
   triples_single_tones = filter(triples) do t
      length(t[2]) == 1
   end

   # 2. Extract the tones from the romanization
   triples_tones = map(triples_single_tones) do triple
      pinyin = triple[2]
      jyutping = triple[3]
      cantonese_tone = parse(Int, match(TONE_REGEX, jyutping).captures[1])
      mandarin_tone = parse(Int, match(TONE_REGEX, pinyin[1]).captures[1])
      (triple[1], mandarin_tone, cantonese_tone)
   end

   mandarin_tones = groupby(t -> t[2] |> only, triples_tones)
   mandarin_to_cantonese =
      OrderedDict(tone => Dict(tone => map(t -> t[1], entries)
         for (tone, entries) in groupby(t -> t[3], characters))
         for (tone, characters) in mandarin_tones)

   cantonese_tones = groupby(t -> t[3] |> only, triples_tones)
   cantonese_to_mandarin =
      OrderedDict(tone => Dict(tone => map(t -> t[1], entries)
         for (tone, entries) in groupby(t -> t[2] |> only, characters))
         for (tone, characters) in cantonese_tones)
   Dict(
      "mandarinToCantonese" => mandarin_to_cantonese,
      "cantoneseToMandarin" => cantonese_to_mandarin
   )
end


function draw_tone_mapping_graph(triples)
   mandarin_tone_counts = extract_tones(triples)
   
   tones_matrix = zeros(4, 6)
   
   for (mandarin_tone, cantonese_tones) in mandarin_tone_counts
      for (cantonese_tone, stat) in cantonese_tones
         tones_matrix[mandarin_tone, cantonese_tone] = stat
      end
   end

   tones_df = DataFrame(tones_matrix, CANTONESE_TONE_LABELS)
   tones_df."Mandarin tone" = MANDARIN_TONE_LABELS
   plot(
      [bar(tones_df, x=Symbol("Mandarin tone"), y=Symbol(y), name=y)
         for y in CANTONESE_TONE_LABELS],
      Layout(
         paper_bgcolor="transparent",
         plot_bgcolor="transparent",
         yaxis=attr(gridcolor="#e0e6f8"),
         font=attr(color="#e0e6f8"),
         width=800,
         height=500
      )
   )
end