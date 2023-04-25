create or replace procedure sp_export_precos_boleto (
Pid_carne     in    number,
Plinha_retorno   out   varchar2
) is
-- -------------------------------------------------------------
-- Procedure criado por Ricardo de Freitas de 02 a 12 de novembro de 1999
-- versao 1.0
-- Imformacoes do Boleto Bancario para a impressora
-- -------------------------------------------------------------
-- ----------------- Definicao das Variaveis -------------------
-- Definicao do Cursor de Busca dos Dados

   cursor c_carne is
   select
      sg_especie_moeda,
      st_boleto_bancario,
      NM_LOCAL_PAGAMT ,
      nr_boleto_bancario,
      decode(vl_descont_abatimt,NULL,0,vl_descont_abatimt) vl_descont_abatimt,
      decode(vl_mora_multa,NULL,0,vl_mora_multa) vl_mora_multa ,
      cd_nosso_numero,
      ds_instrucoes,

      dt_pagamt,
      decode(vl_pagamt,NULL,0,vl_pagamt) vl_pagamt,
      id_pedido,
   
      nm_cliente,
      tp_cliente,
      tp_sexo,

      nm_rua,
      nm_bairro,
      nm_cidade,
      sg_estado,
      nm_pais,
      nr_cep,
      ds_complemento,

      cd_agencia,
      nm_agencia, 
      nm_banco,
      to_number(cd_banco) cd_banco,
      nr_carteira,
      nr_conta_corrente,
      cd_campanha

   from VW_SP_INTERFACE_EXPORT_BOLETO

   where 
         ( ST_BOLETO_BANCARIO = 'BIN' or
           ST_BOLETO_BANCARIO = 'BSR' ) and
         nr_BOLETO_BANCARIO = Pid_carne

   group by DT_PAGAMT  , nr_boleto_bancario , CD_BANCO, NM_BANCO, CD_AGENCIA, NM_AGENCIA, SG_ESPECIE_MOEDA,
      nr_conta_corrente, nr_carteira,
      CD_NOSSO_NUMERO,NM_PAIS,SG_ESTADO,NM_CIDADE,NR_CEP,nm_rua, nm_bairro, ds_complemento,
      NM_CLIENTE, ST_BOLETO_BANCARIO,
      NM_LOCAL_PAGAMT, vl_descont_abatimt, vl_mora_multa, ds_instrucoes,
      vl_pagamt, id_pedido,tp_cliente,tp_sexo,cd_campanha

   order by nr_boleto_bancario, DT_PAGAMT;

-- -----

-- 12 x --
   vCTEX_PCODE01      CHAR(2);
   vCTEX_PARC01       CHAR(2);
   vCTEX_FILLER501    CHAR(9);
   vCTEX_BAL01        CHAR(11);
   vCTEX_VENCTO01     CHAR(9);
   vCTEX_DATA_MAX01     CHAR(9);
   vCTEX_VLR_MULTA01    CHAR(7);
   vCTEX_CR_23701       CHAR(2);    -- CARTEIRA [06]
   vCTEX_FILLER701    CHAR(1);
   vCTEX_NUM_23701      CHAR(11);   -- NOSSO NUMERO (id_pagmt_agendado) [0000]
   vCTEX_FILLER801    CHAR(1);
   vCTEX_DAC_23701      CHAR(1);    -- DIGITO DE AUTO CORRECAO
-- 12 x --

-- Outras Variaveis
   Vbrancos                  char(40);
   Vzeros                    char(20);
   vContador_Ciclos          number;
   vI1                       number;
   vI2                       number;
   vI3                       number;
   vParcelas                 char(2);

-- Inicio Programa --
begin
   vContador_Ciclos := 0 ;
   Vbrancos := '                                        ';
   Vzeros := '00000000000000000000';
   Plinha_retorno := '' ;
   -- Escrita do Arquivo de Interface --
      for r_carne in c_carne loop
         vContador_Ciclos := vContador_Ciclos + 1 ;

         vCTEX_PARC01       := substr(rtrim(ltrim(to_char(vContador_Ciclos,'00'))) ,1,2);

         vCTEX_PCODE01      := substr(Vbrancos,1,2);
         
         vCTEX_FILLER501    := substr(Vzeros,1,9);

         vI1 := round(r_carne.VL_PAGAMT * 100) ;
         vCTEX_BAL01        := rtrim(ltrim(to_char(vI1,substr(Vzeros,1,11)))) ;

         vCTEX_VENCTO01     := substr(Vbrancos,1,1) || to_char(r_carne.DT_PAGAMT,'YYYYMMDD');
         vCTEX_DATA_MAX01   := substr(Vbrancos,1,1) || to_char(r_carne.DT_PAGAMT + 7,'DDMMYYYY');

         vI1 := round(r_carne.VL_MORA_MULTA * 100) ;
         vCTEX_VLR_MULTA01  := rtrim(ltrim(to_char(vI1,substr(Vzeros,1,7)))) ;

         vCTEX_CR_23701     := substr(r_carne.CD_NOSSO_NUMERO,1,2); -- CARTEIRA [06]
         vCTEX_FILLER701    := substr(Vbrancos,1,1);
         vCTEX_NUM_23701    := substr(r_carne.CD_NOSSO_NUMERO,4,11); -- NOSSO NUMERO
         vCTEX_FILLER801    := substr(Vbrancos,1,1);
         vCTEX_DAC_23701    := substr(r_carne.CD_NOSSO_NUMERO,16,1); -- DIGITO DE AUTO CORRECAO

         Plinha_retorno := Plinha_retorno ||
            vCTEX_PCODE01 || vCTEX_PARC01 || vCTEX_FILLER501 ||
            vCTEX_BAL01 || vCTEX_VENCTO01 || vCTEX_DATA_MAX01 ||
            vCTEX_VLR_MULTA01 || vCTEX_CR_23701 || vCTEX_FILLER701 ||
            vCTEX_NUM_23701 || vCTEX_FILLER801 || vCTEX_DAC_23701 ;
      end loop;

      -- zerando variaveis --
      vCTEX_VENCTO01     := substr(Vbrancos,1,1) || substr(Vzeros,1,8);
      vCTEX_DATA_MAX01   := substr(Vbrancos,1,1) || substr(Vzeros,1,8);
      vCTEX_VLR_MULTA01  := substr(Vzeros,1,7);
      vCTEX_CR_23701     := substr(Vzeros,1,2);
      vCTEX_NUM_23701    := substr(Vzeros,4,11);
      vCTEX_DAC_23701    := substr(Vzeros,16,1);
      vCTEX_BAL01        := substr(Vzeros,1,11);
      vCTEX_PARC01       := substr(Vzeros,1,2);

      -- terminando de completar as 12 folhas do carne --
--      sp_log ('boleto' , 'sp_export_precos_boleto', 'OK' , '' ,
--               'Folhas com dados : ' || vContador_Ciclos || ' Id ' || Pid_carne);
      vI3 := vContador_Ciclos;
      while vContador_Ciclos < 12 loop
         vContador_Ciclos := vContador_Ciclos + 1 ;

         Plinha_retorno := Plinha_retorno ||
            vCTEX_PCODE01 || vCTEX_PARC01 || vCTEX_FILLER501 ||
            vCTEX_BAL01 || vCTEX_VENCTO01 || vCTEX_DATA_MAX01 ||
            vCTEX_VLR_MULTA01 || vCTEX_CR_23701 || vCTEX_FILLER701 ||
            vCTEX_NUM_23701 || vCTEX_FILLER801 || vCTEX_DAC_23701 ;
      end loop;

      -- acrescentar quantas folhas
      vParcelas := rtrim(ltrim(to_char(vI3,'00'))) ;
      Plinha_retorno := vParcelas || Plinha_retorno;

-- escreve uma linha no arquivo de export
--      sp_log ('boleto' , 'sp_export_precos_boleto', 'OK' , '' ,
--               substr(Plinha_retorno,1,190) || ' ...' );
-- end if;

-- Fim do Procedure
end sp_export_precos_Boleto;

