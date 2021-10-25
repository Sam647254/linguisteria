function draw_tone_mapping_graph(triples)
   # 1. Extract the tones from the romanization
   triples_tones = map(triples) do triple
      pinyin = triple[2]
      jyutping = triple[3]
      cantonese_tone = parse(Int, match(CANTONESE_TONE_REGEX, jyutping).captures[1])
      mandarin_tone = map(pinyin) do p
         normalized = Unicode.normalize(p, decompose=true)
         findfirst(tone -> contains(normalized, tone), MANDARIN_TONES)
      end
      (triple[1], mandarin_tone, cantonese_tone)
   end
   
   # 2. Filter out polyphones
   triples_single_tones = filter(triples_tones) do t
      length(t[2]) == 1
   end
   
   mandarin_tone_groups = groupby(t -> t[2] |> only, triples_single_tones)
   mandarin_tone_counts =
      OrderedDict(tone => Dict(tone => length(entries)/length(characters)
         for (tone, entries) in groupby(t -> t[3], characters))
         for (tone, characters) in mandarin_tone_groups)
   
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