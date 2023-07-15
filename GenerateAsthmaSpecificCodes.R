definite_asthma_codes = read.delim('asthma_codes_specific.txt', sep = ',')
medcodes=read.delim('medical.txt')
definite_asthma_codes <-definite_asthma_codes %>%
  left_join(medcodes, by='medcode')
# remove the term id and keep only the read code
definite_asthma_codes<-definite_asthma_codes %>%
  mutate(readcode_new=substr(readcode,1,5))
definite_asthma_codes <-definite_asthma_codes %>%
  select(medcode,readcode,readcode_new,readterm)

save(definite_asthma_codes, file='DefiniteAsthmaCodes.Rdata')
definite_asthma_codes
