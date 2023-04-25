create or replace procedure sp_interface_import_boleto (
Pcd_retorno   out   varchar2)
is
-- -----------------------------------------------------------------------
-- Procedure criado por Alexsandra Bonomo de Matos em 15/09/1999
-- modificado por Ricardo de Freitas de 30 outubro a 09 de novembro de 1999
-- versao 1.0
-- Transfere informacoes do boleto do arquivo Bradesco para o banco de dados
-- -----------------------------------------------------------------------
-- ----------------- Definicao das Variaveis -----------------------------
   
   -- Variaveis do Arquivo de Interface  
   Vcd_ident_reg      char(1);   --codigo de identificacao do registro
                                 -- [0] = header label
                                 -- [1] = detalhe
                                 -- [9] = trailler

   -- D E T A L H E --
   Vtp_insc_emp       char(2);   -- tipo de inscricao da empresa
                                 -- [01] = CPF
                                 -- [02] = CGC
                                 -- [03] = PIS/PASEP
                                 -- [98] = Nao tem
                                 -- [99] = Outros
   Vnr_insc_emp       char(14);  -- numero de inscricao da empresa
                                 -- [CGC/CPF numero filial controle]
   -- ZEROS           (3)        -- [000]
   Vcd_ident_emp      char(17);  -- codigo de identificacao da empresa cedente no banco
                                 -- [ZERO carteira agencia conta corrente]
   Vnr_ctrl_participa char(25);  -- numero controle do participante / uso da empresa
   -- ZEROS           (8)        -- [00000000]
   Vnr_ident_titulo   char(12);  -- numero de identificacao do titulo
   -- BRANCOS         (10)       -- [          ]
   -- ZEROS           (12)       -- [000000000000]
   -- RATEIO          (1)        -- [R] [ ]
   -- ZEROS           (2)        -- [00]
   -- carteira        (1)        -- [0] a [9]
   Vcd_ident_ocorr    char(2);   -- codigo de identificacao da ocorrencia
   Vdt_ocorr_banco    char(6);   -- data da ocorrencia no banco
   Vnr_doc            char(10);  -- numero do documento
   Vid_titulo_banco   char(20);  -- identificacao do titulo no banco
   Vdt_vencimt_titulo char(6);   -- data vencimento do titulo
   Vvl_titulo         char(13);  -- valor do titulo
   Vcd_banco_cobr     char(3);   --codigo do banco camara de compensacao
   Vcd_agencia_cobr   char(5);   --codigo da agencia do banco cobrador
   -- BRANCOS         (2)        -- [  ]
   Vvl_despesa        char(13);   -- despesas de cobranca codg 02 e 28
   Vvl_outra_despesa  char(13);   -- despesas de cobranca
   -- ZEROS           (13)       -- [0000000000000]
   Vvl_iof            char(13);       -- IOF devido
   Vvl_abatimento     char(13);  -- abatimento concedido sobre o titulo
   Vvl_desconto_conc  char(13);  -- desconto concedido
   Vvl_cobrado        char(10);  -- valor total cobrado
   Vvl_juros_mora     char(13);  -- juros de mora
   -- ZEROS           (13)       -- [0000000000000]
   -- BRANCOS         (2)        -- [  ]
   Vcd_motivo_ocur_19 char(1);   -- [A] = aceito
                                 -- [D] = desprezado    
   Vdt_credito        char(6);  -- Data do credito
   -- BRANCOS         (17)        -- [                 ]
   Vcd_motivo_ocur_110 char(10);   -- motivo
   -- BRANCOS         (66)        -- [ ... ]
   -- numero sequencial (6)

   -- H E A D E R  L A B E L --

   -- T R A I L L E R --

------------------------------------------
    -- Outras Variaveis

    Vnosso_numero             char(11);
    path_import               parametros_interface.nm_path_boleto_import%type;
    arquivo_import            parametros_interface.nm_arquivo_boleto_import%type;
                              -- CBDDMMxx.REM xx = 00 a ZZ
    semaforo_import           parametros_interface.nm_semaforo_boleto_import%type;

    linha_arquivo_imp         varchar(400);    
    dt_processamento          date; -- usado no log
    count_register            number; -- usado no log
    id                        utl_file.file_type;
    chkfile                   boolean;
    bleituradados             boolean;
    bfim_arquivo              boolean;
    
---------------------
-- Inicio Programa --
---------------------

begin

   bleituradados := true;
   bfim_arquivo := false;
   count_register := 0;
   dt_processamento := sysdate;
   Pcd_retorno := 'OK';

  select 
      nm_path_boleto_import, 
      nm_arquivo_boleto_import,
      nm_semaforo_boleto_import
  into
    path_import,               
    arquivo_import,            
    semaforo_import             
  from
    parametros_interface;
      
  -- Abertura do Arquivo de import
  id := utl_file.fopen(path_import , arquivo_import, 'r');
  chkfile := utl_file.is_open (id);

  if not chkfile Then
      Pcd_retorno := 'ERRO';
      sp_log ('boleto' , 'sp_interface_import_boleto', 'ERRO' , '-200000' ,
            substr('Arquivo ' || path_import || arquivo_import || ' nao encontrado',1,255) );
  else
    while ((not bfim_arquivo) and bleituradados) loop
       begin
         utl_file.get_line (id ,linha_arquivo_imp);

         Vcd_ident_reg := substr(linha_arquivo_imp,1,1);

         -- Leitura do Header Label --
         if Vcd_ident_reg = 0 then
            if '2RETORNO01COBRAN' <>  substr(linha_arquivo_imp,2,16) then
               Pcd_retorno := 'ERRO';
               bleituradados := false;
               sp_log ('boleto' , 'sp_interface_import_boleto', 'ERRO' , '-200001' ,
                  substr('Arquivo ' || path_import || arquivo_import || ' com Header label errado ' || linha_arquivo_imp,1,255) );

            end if;
         end if;
         
         -- leitura do Trailler --
         if Vcd_ident_reg = 9 then
            if '201237' <>  substr(linha_arquivo_imp,2,6) then
               Pcd_retorno := 'ERRO';
               bleituradados := false;
               sp_log ('boleto' , 'sp_interface_import_boleto', 'ERRO' , '-200002' ,
                  substr('Arquivo ' || path_import || arquivo_import || ' com Trailer errado ' || linha_arquivo_imp,1,255) );
            else
               bfim_arquivo := true;
            end if;
         end if;
   
         -- leitura do Detalhe --
         if Vcd_ident_reg = 1 then
            count_register := count_register + 1;
            Vtp_insc_emp := rtrim(substr(linha_arquivo_imp,2,2));
            Vnr_insc_emp := rtrim(substr(linha_arquivo_imp,4,14));
            Vcd_ident_emp := rtrim(substr(linha_arquivo_imp,21,17));
            Vnr_ctrl_participa := rtrim(substr(linha_arquivo_imp,38,25));
            Vnr_ident_titulo := rtrim(substr(linha_arquivo_imp,71,12));
            Vcd_ident_ocorr  := rtrim(substr(linha_arquivo_imp,109,2));
            Vdt_ocorr_banco  := rtrim(substr(linha_arquivo_imp,111,6));
            Vnr_doc :=  rtrim(substr(linha_arquivo_imp,117,10));
            Vid_titulo_banco := rtrim(substr(linha_arquivo_imp,127,20));
            Vdt_vencimt_titulo := rtrim(substr(linha_arquivo_imp,147,6));
            Vvl_titulo := rtrim(substr(linha_arquivo_imp,153,13));
            Vcd_banco_cobr   := rtrim(substr(linha_arquivo_imp,166,3));
            Vcd_agencia_cobr := rtrim(substr(linha_arquivo_imp,169,5));
            Vvl_despesa := rtrim(substr(linha_arquivo_imp,176,13));
            Vvl_outra_despesa := rtrim(substr(linha_arquivo_imp,189,13));
            Vvl_iof := rtrim(substr(linha_arquivo_imp,215,13));
            Vvl_abatimento := rtrim(substr(linha_arquivo_imp,228,13));
            Vvl_desconto_conc := rtrim(substr(linha_arquivo_imp,241,13));
            Vvl_cobrado := rtrim(substr(linha_arquivo_imp,254,13));
            Vvl_juros_mora := rtrim(substr(linha_arquivo_imp,267,13));
            Vcd_motivo_ocur_19 := rtrim(substr(linha_arquivo_imp,295,1));
            Vdt_credito := rtrim(substr(linha_arquivo_imp,296,6));
            Vcd_motivo_ocur_110 := rtrim(substr(linha_arquivo_imp,319,10));

            -- desmontar para obter o nosso numero
            Vnosso_numero := substr(Vnr_ident_titulo || '000000000000',1,11);
            
            begin
               -- Fazer Update na tabela de boleto bancario
               update boleto_bancario
               set st_boleto_bancario = 'BPG'
               where
                  (st_boleto_bancario = 'BIP' OR
                  st_boleto_bancario = 'BRI') AND
                  id_boleto_bancario = Vnosso_numero;
   
               -- Fazer Update na tabela de pagamento agendado
               update pagamt_agendado
               set st_pagamt = 'CON'
               where
                  st_pagamt = 'ACB'  AND
                  tp_pagamt_agendado ='BB' AND
                  id_boleto_bancario = Vnosso_numero;

            exception when others then
               Pcd_retorno := 'ERRO';
               bleituradados := false;
               rollback;
            end ;
         end if ; -- fim dos dados no caso detalhe

      exception when no_data_found then
         Pcd_retorno := 'ERRO';
         bfim_arquivo := false; -- nao achou o trailler
      end;
    -- Fim do while
    end loop;

   if (not bleituradados) or (not bfim_arquivo) then
      -- houve erro no arquivo ou ele nao esta todo no diretorio
      Pcd_retorno := 'ERRO';
      count_register := 0;
      rollback;
   end if;

   -- Fechamento do arquivo de import
   utl_file.fclose(id);

   end if;


  -- Registro na Tabela de Log
   sp_log ('boleto' , 'sp_interface_import_boleto', 'OK' , '' ,
           substr('Arquivo ' || path_import || arquivo_import || ' data ' || 
           dt_processamento || ' registros ' ||  ltrim(to_char(count_register,'00000')) ,1,255) );

--   Commit;
   exception when others then
      Pcd_retorno := 'ERRO';
      rollback;

end sp_interface_import_boleto;

