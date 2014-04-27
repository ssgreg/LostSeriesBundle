
text = ''' cryptlib mem mem_dbg cversion ex_data cpt_err &
 ebcdic uid o_time o_str o_dir o_init &
 o_names obj_dat obj_lib obj_err obj_xref &
 md4_dgst md4_one &
 md5_dgst md5_one &
 sha_dgst sha1dgst sha_one sha1_one sha256 sha512 &
 hmac hm_ameth hm_pmeth &
 rmd_dgst rmd_one &
 wp_dgst &
 cbc_cksm cbc_enc cfb64enc cfb_enc &
 ecb3_enc ecb_enc enc_read enc_writ &
 fcrypt ofb64enc ofb_enc pcbc_enc &
 qud_cksm rand_key rpc_enc set_key &
 xcbc_enc &
 str2key cfb64ede ofb64ede ede_cbcm_enc des_old des_old2 &
 read2pwd &
 aes_misc aes_ecb aes_cfb aes_ofb &
 aes_ctr aes_ige aes_wrap aes_fast &
 rc2_ecb rc2_skey rc2_cbc rc2cfb64 rc2ofb64 &
 rc4_utl &
 bf_skey bf_ecb bf_cfb64 bf_ofb64 &
 c_skey c_ecb c_cfb64 c_ofb64 &
 cmll_ecb cmll_ofb &
 cmll_cfb cmll_ctr cmll_utl &
 seed seed_ecb seed_cbc seed_cfb seed_ofb &
 cbc128 ctr128 cts128 cfb128 ofb128 gcm128 &
 ccm128 xts128 &
 bn_add bn_div bn_exp bn_lib bn_ctx bn_mul bn_mod &
 bn_print bn_rand bn_shift bn_word bn_blind &
 bn_kron bn_sqrt bn_gcd bn_prime bn_err bn_sqr &
 bn_recp bn_mont bn_mpi bn_exp2 bn_gf2m bn_nist &
 bn_const bn_x931p &
 ec_lib ecp_smpl ecp_mont ecp_nist ec_cvt ec_mult &
 ec_err ec_curve ec_check ec_print ec_asn1 ec_key &
 ec2_smpl ec2_mult ec_ameth ec_pmeth eck_prn &
 ecp_oct ec2_oct ec_oct &
 rsa_eay rsa_gen rsa_lib rsa_sign rsa_saos rsa_err &
 rsa_pk1 rsa_ssl rsa_none rsa_oaep rsa_chk rsa_null &
 rsa_pss rsa_x931 rsa_asn1 rsa_ameth rsa_prn &
 rsa_pmeth rsa_crpt &
 dsa_gen dsa_key dsa_lib dsa_asn1 dsa_vrf dsa_sign &
 dsa_err dsa_ossl dsa_ameth dsa_pmeth dsa_prn &
 ecs_lib ecs_asn1 ecs_ossl ecs_sign ecs_vrf ecs_err &
 dh_asn1 dh_gen dh_key dh_lib dh_check dh_err &
 dh_ameth dh_pmeth dh_prn &
 ech_lib ech_ossl ech_key ech_err &
 dso_dl dso_dlfcn dso_err dso_lib dso_null &
 dso_openssl &
 eng_err eng_lib eng_list eng_init eng_ctrl &
 eng_table eng_pkey eng_fat eng_all &
 tb_rsa tb_dsa tb_ecdsa tb_dh tb_ecdh tb_rand tb_store &
 tb_cipher tb_digest tb_pkmeth tb_asnmth &
 eng_openssl eng_cnf eng_dyn eng_cryptodev &
 eng_rsax eng_rdrand &
 buffer buf_str buf_err &
 bio_lib bio_cb bio_err &
 bss_mem bss_null bss_fd &
 bss_file bss_sock bss_conn &
 bf_null bf_buff b_print b_dump &
 b_sock bss_acpt bf_nbio bss_log bss_bio &
 stack &
 lhash lh_stats &
 md_rand randfile rand_lib rand_err rand_egd &
 rand_win rand_unix rand_os2 rand_nw &
 err err_all err_prn &
 encode digest evp_enc evp_key evp_acnf evp_cnf &
 e_des e_bf e_idea e_des3 e_camellia &
 e_rc4 e_aes names e_seed &
 e_xcbc_d e_rc2 e_cast e_rc5 &
 m_null m_md2 m_md4 m_md5 m_sha m_sha1 m_wp &
 m_dss m_dss1 m_mdc2 m_ripemd m_ecdsa &
 p_open p_seal p_sign p_verify p_lib p_enc p_dec &
 bio_md bio_b64 bio_enc evp_err e_null &
 c_all c_allc c_alld evp_lib bio_ok &
 evp_pkey evp_pbe p5_crpt p5_crpt2 &
 pmeth_lib pmeth_fn pmeth_gn m_sigver evp_fips &
 e_aes_cbc_hmac_sha1 e_rc4_hmac_md5 &
 a_object a_bitstr a_utctm a_gentm a_time a_int a_octet &
 a_print a_type a_set a_dup a_d2i_fp a_i2d_fp &
 a_enum a_utf8 a_sign a_digest a_verify a_mbstr a_strex &
 x_algor x_val x_pubkey x_sig x_req x_attrib x_bignum &
 x_long x_name x_x509 x_x509a x_crl x_info x_spki nsseq &
 x_nx509 d2i_pu d2i_pr i2d_pu i2d_pr &
 t_req t_x509 t_x509a t_crl t_pkey t_spki t_bitst &
 tasn_new tasn_fre tasn_enc tasn_dec tasn_utl tasn_typ &
 tasn_prn ameth_lib &
 f_int f_string n_pkey &
 f_enum x_pkey a_bool x_exten bio_asn1 bio_ndef asn_mime &
 asn1_gen asn1_par asn1_lib asn1_err a_bytes a_strnid &
 evp_asn1 asn_pack p5_pbe p5_pbev2 p8_pkey asn_moid &
 pem_sign pem_seal pem_info pem_lib pem_all pem_err &
 pem_x509 pem_xaux pem_oth pem_pk8 pem_pkey pvkfmt &
 x509_def x509_d2 x509_r2x x509_cmp &
 x509_obj x509_req x509spki x509_vfy &
 x509_set x509cset x509rset x509_err &
 x509name x509_v3 x509_ext x509_att &
 x509type x509_lu x_all x509_txt &
 x509_trs by_file by_dir x509_vpm &
 v3_bcons v3_bitst v3_conf v3_extku v3_ia5 v3_lib &
 v3_prn v3_utl v3err v3_genn v3_alt v3_skey v3_akey v3_pku &
 v3_int v3_enum v3_sxnet v3_cpols v3_crld v3_purp v3_info &
 v3_ocsp v3_akeya v3_pmaps v3_pcons v3_ncons v3_pcia v3_pci &
 pcy_cache pcy_node pcy_data pcy_map pcy_tree pcy_lib &
 v3_asid v3_addr &
 conf_err conf_lib conf_api conf_def conf_mod &
 conf_mall conf_sap &
 txt_db &
 pk7_asn1 pk7_lib pkcs7err pk7_doit pk7_smime pk7_attr &
 pk7_mime bio_pk7 &
 p12_add p12_asn p12_attr p12_crpt p12_crt p12_decr &
 p12_init p12_key p12_kiss p12_mutl &
 p12_utl p12_npas pk12err p12_p8d p12_p8e &
 comp_lib comp_err &
 c_rle c_zlib &
 ocsp_asn ocsp_ext ocsp_ht ocsp_lib ocsp_cl &
 ocsp_srv ocsp_prn ocsp_vfy ocsp_err &
 ui_err ui_lib ui_openssl ui_util ui_compat &
 krb5_asn &
 cms_lib cms_asn1 cms_att cms_io cms_smime cms_err &
 cms_sd cms_dd cms_cd cms_env cms_enc cms_ess &
 cms_pwri &
 pqueue &
 ts_err ts_req_utils ts_req_print ts_rsp_utils ts_rsp_print &
 ts_rsp_sign ts_rsp_verify ts_verify_ctx ts_lib ts_conf &
 ts_asn1 &
 srp_lib srp_vfy &
 cmac cm_ameth cm_pmeth &
 e_4758cca e_aep e_atalla e_cswift e_gmp e_chil e_nuron e_sureware e_ubsec e_padlock e_capi &
 e_gost_err gost2001_keyx gost2001 gost89 gost94_keyx gost_ameth gost_asn1 gost_crypt gost_init_paramset &
 gost_ctl gost_eng gosthash gost_keywrap gost_md gost_params gost_pmeth gost_sign &
 callback'''

my =  '''cbc128 &
  md5_dgst &
  md5_one &
  bn_add &
  bn_asm &
  bn_blind &
  bn_const &
  bn_ctx &
  bn_div &
  bn_err &
  bn_exp &
  bn_exp2 &
  bn_gcd &
  bn_gf2m &
  bn_kron &
  bn_lib &
  bn_mod &
  bn_mont &
  bn_mpi &
  bn_mul &
  bn_nist &
  bn_prime &
  bn_print &
  bn_rand &
  bn_recp &
  bn_shift &
  bn_sqr &
  bn_sqrt &
  bn_word &
  bn_x931p &
  lhash &
  stack &
  buf_err &
  buf_str &
  buffer &
  sha_dgst &
  sha_one &
  sha1_one &
  sha1dgst &
  sha1test &
  sha256 &
  sha256t &
  sha512 &
  sha512t &
  shatest &
  rsa_sign &
  dsa_ameth &
  dsa_asn1 &
  dsa_depr &
  dsa_err &
  dsa_gen &
  dsa_key &
  dsa_lib &
  dsa_ossl &
  dsa_pmeth &
  dsa_prn &
  dsa_sign &
  dsa_vrf &
  dsagen &
  dsatest &
  dh_ameth &
  dh_asn1 &
  dh_check &
  dh_depr &
  dh_err &
  dh_gen &
  dh_key &
  dh_lib &
  dh_pmeth &
  dh_prn &
  dhtest &
  p1024 &
  p192 &
  p512 &
  ec_ameth &
  ec_asn1 &
  ec_check &
  ec_curve &
  ec_cvt &
  ec_err &
  ec_key &
  ec_lib &
  ec_mult &
  ec_oct &
  ec_pmeth &
  ec_print &
  ec2_mult &
  ec2_oct &
  ec2_smpl &
  eck_prn &
  ecp_mont &
  ecp_nist &
  ecp_nistp224 &
  ecp_nistp256 &
  ecp_nistp521 &
  ecp_nistputil &
  ecp_oct &
  ecp_smpl &
  ectest &
  hm_ameth &
  hm_pmeth &
  hmac &
  hmactest &
  cm_ameth &
  cm_pmeth &
  cmac &
  a_bitstr &
  a_bool &
  a_bytes &
  a_d2i_fp &
  a_digest &
  a_dup &
  a_enum &
  a_gentm &
  a_i2d_fp &
  a_int &
  a_mbstr &
  a_object &
  a_octet &
  a_print &
  a_set &
  a_sign &
  a_strex &
  a_strnid &
  a_time &
  a_type &
  a_utctm &
  a_utf8 &
  a_verify &
  ameth_lib &
  asn_mime &
  asn_moid &
  asn_pack &
  asn1_err &
  asn1_gen &
  asn1_lib &
  asn1_par &
  bio_asn1 &
  bio_ndef &
  d2i_pr &
  d2i_pu &
  evp_asn1 &
  f_enum &
  f_int &
  f_string &
  i2d_pr &
  i2d_pu &
  n_pkey &
  nsseq &
  p5_pbe &
  p5_pbev2 &
  p8_pkey &
  t_bitst &
  t_crl &
  t_pkey &
  t_req &
  t_spki &
  t_x509 &
  t_x509a &
  tasn_dec &
  tasn_enc &
  tasn_fre &
  tasn_new &
  tasn_prn &
  tasn_typ &
  tasn_utl &
  x_algor &
  x_attrib &
  x_bignum &
  x_crl &
  x_exten &
  x_info &
  x_long &
  x_name &
  x_nx509 &
  x_pkey &
  x_pubkey &
  x_req &
  x_sig &
  x_spki &
  x_val &
  x_x509 &
  x_x509a &
  rsa_ameth &
  rsa_asn1 &
  rsa_chk &
  rsa_crpt &
  rsa_depr &
  rsa_eay &
  rsa_err &
  rsa_gen &
  rsa_lib &
  rsa_none &
  rsa_null &
  rsa_oaep &
  rsa_pk1 &
  rsa_pmeth &
  rsa_prn &
  rsa_pss &
  rsa_saos &
  rsa_sign &
  rsa_ssl &
  rsa_test &
  rsa_x931 &
  cms_asn1 &
  cms_att &
  cms_cd &
  cms_dd &
  cms_enc &
  cms_env &
  cms_err &
  cms_ess &
  cms_io &
  cms_lib &
  cms_pwri &
  cms_sd &
  cms_smime &
  bio_pk7 &
  dec &
  enc &
  example &
  pk7_asn1 &
  pk7_attr &
  pk7_dgst &
  pk7_doit &
  pk7_lib &
  pk7_mime &
  pk7_smime &
  pkcs7err &
  sign &
  verify &
  by_dir &
  by_file &
  x_all &
  x509_att &
  x509_cmp &
  x509_d2 &
  x509_def &
  x509_err &
  x509_ext &
  x509_lu &
  x509_obj &
  x509_r2x &
  x509_req &
  x509_set &
  x509_trs &
  x509_txt &
  x509_v3 &
  x509_vfy &
  x509_vpm &
  x509cset &
  x509name &
  x509rset &
  x509spki &
  x509type &
  bio_b64 &
  bio_enc &
  bio_md &
  bio_ok &
  c_all &
  c_allc &
  c_alld &
  digest &
  e_aes &
  e_aes_cbc_hmac_sha1 &
  e_bf &
  e_camellia &
  e_cast &
  e_des &
  e_des3 &
  e_idea &
  e_null &
  e_old &
  e_rc2 &
  e_rc4 &
  e_rc4_hmac_md5 &
  e_rc5 &
  e_seed &
  e_xcbc_d &
  encode &
  evp_acnf &
  evp_cnf &
  evp_enc &
  evp_err &
  evp_fips &
  evp_key &
  evp_lib &
  evp_pbe &
  evp_pkey &
  evp_test &
  m_dss &
  m_dss1 &
  m_ecdsa &
  m_md2 &
  m_md4 &
  m_md5 &
  m_mdc2 &
  m_null &
  m_ripemd &
  m_sha &
  m_sha1 &
  m_sigver &
  m_wp &
  names &
  openbsd_hw &
  p_dec &
  p_enc &
  p_lib &
  p_open &
  p_seal &
  p_sign &
  p_verify &
  p5_crpt &
  p5_crpt2 &
  pmeth_fn &
  pmeth_gn &
  pmeth_lib &
  ecdsatest &
  ecs_asn1 &
  ecs_err &
  ecs_lib &
  ecs_ossl &
  ecs_sign &
  ecs_vrf &
  ecdhtest &
  ech_err &
  ech_key &
  ech_lib &
  ech_ossl &
  pcy_cache &
  pcy_data &
  pcy_lib &
  pcy_map &
  pcy_node &
  pcy_tree &
  tabtest &
  v3_addr &
  v3_akey &
  v3_akeya &
  v3_alt &
  v3_asid &
  v3_bcons &
  v3_bitst &
  v3_conf &
  v3_cpols &
  v3_crld &
  v3_enum &
  v3_extku &
  v3_genn &
  v3_ia5 &
  v3_info &
  v3_int &
  v3_lib &
  v3_ncons &
  v3_ocsp &
  v3_pci &
  v3_pcia &
  v3_pcons &
  v3_pku &
  v3_pmaps &
  v3_prn &
  v3_purp &
  v3_skey &
  v3_sxnet &
  v3_utl &
  v3err &
  v3prin &
  o_names &
  obj_dat &
  obj_err &
  obj_lib &
  obj_xref &
  aes_cbc &
  aes_cfb &
  aes_core &
  aes_ctr &
  aes_ecb &
  aes_fast &
  aes_ige &
  aes_misc &
  aes_ofb &
  aes_wrap &
  aes_x86core &
  eng_all &
  eng_cnf &
  eng_cryptodev &
  eng_ctrl &
  eng_dyn &
  eng_err &
  eng_fat &
  eng_init &
  eng_lib &
  eng_list &
  eng_openssl &
  eng_pkey &
  eng_rdrand &
  eng_rsax &
  eng_table &
  enginetest &
  tb_asnmth &
  tb_cipher &
  tb_dh &
  tb_digest &
  tb_dsa &
  tb_ecdh &
  tb_ecdsa &
  tb_pkmeth &
  tb_rand &
  tb_rsa &
  tb_store &
  conf_api &
  conf_def &
  conf_err &
  conf_lib &
  conf_mall &
  conf_mod &
  conf_sap &
  p12_add &
  p12_asn &
  p12_attr &
  p12_crpt &
  p12_crt &
  p12_decr &
  p12_init &
  p12_key &
  p12_kiss &
  p12_mutl &
  p12_npas &
  p12_p8d &
  p12_p8e &
  p12_utl &
  pk12err &
  err &
  err_all &
  err_prn &
  b_dump &
  b_print &
  bf_buff &
  bf_lbuf &
  bf_nbio &
  bf_null &
  bio_cb &
  bio_err &
  bio_lib &
  bss_acpt &
  bss_bio &
  bss_conn &
  bss_fd &
  bss_file &
  bss_mem &
  bss_null &
  bss_sock &
  dso_beos &
  dso_dl &
  dso_dlfcn &
  dso_err &
  dso_lib &
  dso_null &
  dso_openssl &
  dso_vms &
  dso_win32 &
  cpt_err &
  cryptlib &
  cversion &
  ebcdic &
  ex_data &
  fips_ers &
  mem &
  mem_clr &
  mem_dbg &
  o_dir &
  o_dir_test &
  o_fips &
  o_init &
  o_str &
  o_time &
  uid &
  pem_all &
  pem_err &
  pem_info &
  pem_lib &
  pem_oth &
  pem_pk8 &
  pem_pkey &
  pem_seal &
  pem_sign &
  pem_x509 &
  pem_xaux &
  pvkfmt &
  ui_compat &
  ui_err &
  ui_lib &
  ui_util &
  ocsp_asn &
  ocsp_cl &
  ocsp_err &
  ocsp_ext &
  ocsp_ht &
  ocsp_lib &
  ocsp_prn &
  ocsp_srv &
  ocsp_vfy &
  c_rle &
  c_zlib &
  comp_err &
  comp_lib &
  md_rand &
  rand_egd &
  rand_err &
  rand_lib &
  rand_nw &
  rand_os2 &
  rand_unix &
  rand_vms &
  rand_win &
  randfile &
  crt_wrapper &
'''


import re
textList = re.findall(r"[\w']+", text)

myList = [x.strip() for x in my.split(' &\n')]


print len(textList)
print len(myList)

result = []

notintext = 0

for i in myList:
  if i in textList:
    textList.remove(i)
  else:
    print "lishnij = {}".format(i)

print len(textList)
print notintext


text1 = text

for i in textList:
  text1 = re.sub(' ' + i + ' ','',text1)

print text1


print len(re.findall(r"[\w']+", text1))
# s = 'randfile randfile1 randfile'

# print re.sub('randfile1','',s)

