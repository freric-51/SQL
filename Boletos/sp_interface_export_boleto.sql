create or replace procedure sp_interface_export_boleto is
-- -------------------------------------------------------------
-- Procedure criado por Alexsandra Bonomo de Matos em 15/09/1999
-- e modificado por Ricardo de Freitas de 27 de outubro de 1999 a 09 de novembro de 1999
-- versao 1.0
-- Imformacoes do Boleto Bancario para a impressora
-- -------------------------------------------------------------
-- ----------------- Definicao das Variaveis -------------------
-- Definicao do Cursor de Busca dos Dados

-- DECODE( LTRIM(cd_agencia), null, ' ', LTRIM(cd_agencia)),

   cursor c_interface is
   select
      sg_especie_moeda,
      st_boleto_bancario,
      NM_LOCAL_PAGAMT ,
      nr_boleto_bancario,
      decode(vl_descont_abatimt,NULL,0,vl_descont_abatimt) vl_descont_abatimt,
      decode(vl_mora_multa,NULL,0,vl_mora_multa) vl_mora_multa,
      cd_nosso_numero,
      ds_instrucoes,

      dt_pagamt,
      decode(vl_pagamt,NULL,0,vl_pagamt) vl_pagamt,
      id_pedido,

      nm_cliente,
      tp_cliente,
      decode(tp_sexo,NULL,'M',tp_sexo) tp_sexo,

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
      cd_campanha,
      nm_empresa

   from VW_SP_INTERFACE_EXPORT_BOLETO

   where
      ST_BOLETO_BANCARIO = 'BIN' or
      ST_BOLETO_BANCARIO = 'BSR'

   group by DT_PAGAMT  , nr_boleto_bancario , CD_BANCO, NM_BANCO, CD_AGENCIA, NM_AGENCIA, SG_ESPECIE_MOEDA,
      nr_conta_corrente, nr_carteira,
      CD_NOSSO_NUMERO,NM_PAIS,SG_ESTADO,NM_CIDADE,NR_CEP,nm_rua, nm_bairro, ds_complemento,
      NM_CLIENTE, ST_BOLETO_BANCARIO,
      NM_LOCAL_PAGAMT, vl_descont_abatimt, vl_mora_multa, ds_instrucoes,
      vl_pagamt, id_pedido,tp_cliente,tp_sexo,cd_campanha,nm_empresa

   order by nr_boleto_bancario, DT_PAGAMT;

-- Variaveis do Arquivo de Interface
      vCETX_SORT         CHAR(4);
      vCTEX_TPAC         CHAR(1);
      vCTEX_CDAC         CHAR(4);
      vCTEX_TCLI         CHAR(2);
      vCTEX_CAMP         CHAR(4);
      vCTEX_TCOB         CHAR(1);
      vCTEX_PROJ         CHAR(3);
      vCTEX_CODCART      CHAR(5);
      vCTEX_NUMTICK      CHAR(2);
      vCTEX_CEP_SORT     CHAR(5);
      vCTEX_CEP_SORT2    CHAR(3);
      vCTEX_ACCNO        CHAR(9);
      vCTEX_SNO          CHAR(3);

      vCTEX_NOME         CHAR(30);   -- NOME DO CLIENTE
      vCTEX_ENDE         CHAR(30);   -- ENDEREÇO DO CLIENTE
      vCTEX_BAIRRO       CHAR(15);   -- BAIRRO DO CLIENTE
      vCTEX_CEP1         CHAR(5);    -- CEP ENDERECO CLIENTE [00000]
      vCTEX_CEP2         CHAR(3);    -- COMPL CEP ENDER CLIENTE [000]
      vCTEX_CIDADE       CHAR(15);   -- CIDADE CLIENTE
      vCTEX_UF           CHAR(2);    -- UNIDADE FEDERACAO CLIENTE

      vCTEX_SEL_CARNET   CHAR(1);
      vCTEX_FILLER       CHAR(4);

      vCTEX_CARTA        CHAR(1);
      vCTEX_TOTREN       CHAR(1);
      vCTEX_GRUPO        CHAR(1);
      vCTEX_QMAG         CHAR(3);
      vCTEX_CONTROLE_MOEDA  CHAR(1);
      vCTEX_ACCNO_DON    CHAR(9);

      vCTEX_SEXO         CHAR(1);

      vCTEX_NUMBCO       CHAR(3);    -- NUMERO BANCO [000]
      vCTEX_NOMBCO       CHAR(12);   -- NOME DO BANCO
      vCTEX_NOMAGCED     CHAR(12);   -- NOME AGENCIA
      vCTEX_CARTEIRA     CHAR(3);

      vCTEX_CODAG        CHAR(4);    -- CODIGO DA AGENCIA

      vCTEX_CONTA        CHAR(7);    -- NUMERO DA CONTA [0000000]
      vCTEX_AG_CEDENTE   CHAR(20);   -- AGENCIA CEDENTE

      vCTEX_ASSINAT      CHAR(3);    -- CODIGO ASSINATURA [000]
      vCTEX_APROM_1      CHAR(4);

-- 12 x --
      vCTEX_CR_237       CHAR(2);    -- CARTEIRA [06]
      vCTEX_NUM_237      CHAR(11);   -- NOSSO NUMERO (id_pagmt_agendado) [0000]
      vCTEX_DAC_237      CHAR(1);    -- DIGITO DE AUTO CORRECAO
-- 12 x --
      vCTEX_FOLHAS_CONCAT   char(782);
-- Outras Variaveis
   vI1                NUMBER;
   vI2                number;
   Vpath_export               parametros_interface.nm_path_boleto_export%type;
   Varquivo_export            parametros_interface.nm_arquivo_boleto_export%type;
   Vsemaforo_export           parametros_interface.nm_semaforo_boleto_export%type;
   VTelefone                  parametros_interface.nr_telefone_atendmt%type;

   dt_processamento          date; -- usado no log
   id                        utl_file.file_type;
   chkfile                   boolean;
   count_register            number; -- usado no log
   Vresultado                number;
   Vbrancos                  char(40);
   Vzeros                    char(20);
   Vid_carne_z1              NUMBER;

-- Inicio Programa --
begin
   count_register := 0;
   dt_processamento := sysdate;
   Vbrancos := '                                        ';
   Vzeros := '00000000000000000000';
   vCETX_SORT := substr(Vbrancos,1,4);
   vCTEX_TPAC := 'F';
   vCTEX_CDAC := 'ONES';
   vCTEX_TCLI := 'SU';
   vCTEX_TCOB := 'D';
   vCTEX_PROJ := '990';
   vCTEX_CODCART := substr(Vbrancos,1,5);
   vCTEX_NUMTICK := '01';
   vCTEX_CEP_SORT := substr(Vzeros,1,5);
   vCTEX_CEP_SORT2 := substr(Vzeros,1,3);
   vCTEX_SNO := '001';
   vCTEX_SEL_CARNET := 'H';
   vCTEX_FILLER := '1100';
   vCTEX_CARTA := substr(Vbrancos,1,1);
   vCTEX_TOTREN := substr(Vbrancos,1,1);
   vCTEX_GRUPO := substr(Vbrancos,1,1);
   vCTEX_QMAG := '001';
   vCTEX_CONTROLE_MOEDA := substr(Vbrancos,1,1);
   vCTEX_ACCNO_DON := substr(Vzeros,1,9);
   vCTEX_APROM_1 := substr(Vbrancos,1,4);

 Vid_carne_z1 := 0 ;
    select
      nm_path_boleto_export,
      nm_arquivo_boleto_export,
      nm_semaforo_boleto_export,
      nr_telefone_atendmt
    into
      Vpath_export,
      Varquivo_export,
      Vsemaforo_export,
      VTelefone
    from
      parametros_interface;

   -- Abertura do Arquivo de export --
   id := utl_file.fopen(Vpath_export , Varquivo_export, 'w');
   chkfile := utl_file.is_open (id);

   if not chkfile Then
--      null;
      sp_log ('boleto' , 'sp_interface_export_Boleto', 'ERRO' , '-211200' ,
              substr('Arquivo ' || Vpath_export || ' ' || Varquivo_export || ' nao encontrado',1,255));
   else
-- dbms_output.put_line( 'entrei no arquivo' );
   -- Escrita do Arquivo de Interface --
      for r_interface in c_interface loop

      if Vid_carne_z1 <> r_interface.nr_BOLETO_BANCARIO then
         Vid_carne_z1 := r_interface.nr_BOLETO_BANCARIO;
         count_register := count_register + 1;

         vCTEX_NOME         := substr(r_interface.NM_CLIENTE || Vbrancos,1,30);
         vCTEX_ENDE         := substr(r_interface.NM_RUA || ' ' || r_interface.DS_COMPLEMENTO || ' ' || Vbrancos,1,30);
         vCTEX_BAIRRO       := substr(r_interface.NM_BAIRRO || Vbrancos,1,15);

         vCTEX_CEP1         := substr(r_interface.NR_CEP || vzeros,1,5);
         vCTEX_CEP2         := substr(r_interface.NR_CEP || vzeros,6,3);

         vCTEX_CIDADE       := substr(r_interface.NM_CIDADE || Vbrancos,1,15);
         vCTEX_UF           := substr(r_interface.SG_ESTADO || Vbrancos,1,2);

         if r_interface.tp_cliente = 'J' then
            vCTEX_SEXO         := 'J';
         else
            vCTEX_SEXO         := substr(r_interface.TP_SEXO,1,1);
         end if ;

         vCTEX_NUMBCO       := substr(ltrim(to_char(r_interface.CD_BANCO))  || vzeros ,1,3);

         vCTEX_NOMBCO       := substr( ltrim(rtrim(substr(r_interface.NM_BANCO,1,11))) || Vbrancos,1,12);
         vCTEX_NOMAGCED     := substr(r_interface.NM_AGENCIA || Vbrancos,1,12);

         vI2 := length(r_interface.CD_AGENCIA)-2 ; -- retirado digito verif.

         vCTEX_CODAG   := substr(ltrim(to_char(to_number(substr(r_interface.CD_AGENCIA,1,vI2)),
                          substr(vzeros,1,3))) ||
                          substr(r_interface.CD_AGENCIA,vI2 + 2,1) ,1,4) ;

         vI2 := length(r_interface.NR_CONTA_CORRENTE)-2 ; -- retirado digito verif.
         if vI2 = 7 then
            vCTEX_CONTA   := substr(r_interface.NR_CONTA_CORRENTE,1,7);
         else
            vCTEX_CONTA   := ltrim(to_char(
                                 to_number(substr(r_interface.NR_CONTA_CORRENTE,1,vi2)
                                ,substr(vzeros,1,6) )
                              )) ||
                             substr(r_interface.NR_CONTA_CORRENTE,vi2 + 2, 1);
         end if;

         vCTEX_AG_CEDENTE   := substr( r_interface.CD_AGENCIA  ||
                              '/' || r_interface.NR_CONTA_CORRENTE ||
                              Vbrancos,1,20); -- AGENCIA CEDENTE & CONTA CORRENTE

         vCTEX_ASSINAT      := substr(Vzeros,1,3); -- CODIGO ASSINATURA [000]

         vCTEX_CR_237       := substr(r_interface.CD_NOSSO_NUMERO,1,2);
         vCTEX_NUM_237      := substr(r_interface.CD_NOSSO_NUMERO,4,11);
         vCTEX_DAC_237      := substr(r_interface.CD_NOSSO_NUMERO,16,1);

         vCTEX_CARTEIRA     := substr(Vzeros,1,1) || vCTEX_CR_237;
         vCTEX_CAMP         := substr(r_interface.CD_CAMPANHA,1,4);

         vCTEX_ACCNO := substr( ltrim(to_char(r_interface.ID_PEDIDO,substr(Vzeros,1,9))),1,9);

         vCTEX_FOLHAS_CONCAT := '';
         sp_export_precos_boleto(r_interface.nr_BOLETO_BANCARIO, vCTEX_FOLHAS_CONCAT );

         -- escreve uma linha no arquivo de export --
         utl_file.put (id , (

                  vCETX_SORT ||
                  vCTEX_TPAC ||
                  vCTEX_CDAC ||
                  vCTEX_TCLI ||
                  vCTEX_CAMP ||
                  vCTEX_TCOB ||
                  vCTEX_PROJ ||
                  vCTEX_CODCART ||
                  vCTEX_NUMTICK ||
                  vCTEX_CEP_SORT ||
                  vCTEX_CEP_SORT2 ||
                  vCTEX_ACCNO ||
                  vCTEX_SNO ||
                  vCTEX_NOME ||
                  vCTEX_ENDE ||
                  vCTEX_BAIRRO ||
                  vCTEX_CEP1 ||
                  vCTEX_CEP2 ||
                  vCTEX_CIDADE ||
                  vCTEX_UF ||
                  vCTEX_SEL_CARNET ||
                  vCTEX_FILLER ||
                  vCTEX_CARTA ||
                  vCTEX_TOTREN ||
                  vCTEX_GRUPO ||
                  vCTEX_QMAG ||
                  vCTEX_CONTROLE_MOEDA ||
                  vCTEX_ACCNO_DON ||
                  vCTEX_SEXO ||
                  vCTEX_NUMBCO ||
                  vCTEX_NOMBCO ||
                  vCTEX_NOMAGCED ||
                  vCTEX_CARTEIRA ||
                  vCTEX_CODAG ||
                  vCTEX_CONTA ||
                  vCTEX_AG_CEDENTE ||
                  vCTEX_ASSINAT ||
                  vCTEX_APROM_1 ||
                     ''));

         utl_file.put (id , (
                  -- ate 12 folhas de cobranca no carne --
                  -- vCTEX_TPARC_1 esta vindo (2) em vCTEX_FOLHAS_CONCAT
                 vCTEX_FOLHAS_CONCAT
                   ));

--         utl_file.new_line (id,1) ;

         utl_file.fclose(id);

         id := utl_file.fopen(Vpath_export , Varquivo_export, 'a');
         chkfile := utl_file.is_open (id);

--
       -- Fim Loop
       -- Estado do Boleto Bancario de 'BIN' para 'BEI' - Transmitido para impressora
       -- pg_boleto_bancario.sp_boleto_enviado (c_item.id_boleto_bancario);

          update boleto_bancario set
             st_boleto_bancario = 'BIP'
          where nr_BOLETO_BANCARIO = Vid_carne_z1 -- r_interface.nr_BOLETO_BANCARIO
             and ST_BOLETO_BANCARIO = 'BIN';

         update boleto_bancario set
             st_boleto_bancario = 'BRI'
          where nr_BOLETO_BANCARIO = r_interface.nr_BOLETO_BANCARIO -- = Vid_carne_z1
             and ST_BOLETO_BANCARIO = 'BSR';

       end if;
       end loop;
    end if;
--
-- Fechamento do arquivo
-- dbms_output.put_line( 'ponto 12 fechar arquivo' );
   utl_file.fclose(id);
      sp_log ('boleto' , 'sp_interface_export_Boleto', 'OK' , '' ,
              'gravado arquivo ' || Vpath_export || Varquivo_export ||
              ' em ' ||  dt_processamento ||
              ' registros ' || to_char(count_register,'00000'));

--
   exception
      when others then
         sp_log ('boleto' , 'sp_interface_export_Boleto', 'ERRO' , '-211206' ,
                  substr(SQLERRM,1,255) );
         rollback;

-- Fim do Procedure
end sp_interface_export_Boleto;

