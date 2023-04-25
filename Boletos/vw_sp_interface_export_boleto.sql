create or replace view vw_sp_interface_export_boleto as
   select distinct
   bb.sg_especie_moeda,
   bb.st_boleto_bancario,
   bb.nm_local_pagamt,
   bb.nr_boleto_bancario,
   bb.vl_descont_abatimt,
   bb.vl_mora_multa,
   bb.cd_nosso_numero,
   bb.ds_instrucoes,

   pa.dt_pagamt,
   pa.vl_pagamt,
   pa.id_pedido,
   
   cl.nm_cliente,
   cl.tp_cliente,
   cl.tp_sexo,

   en.nm_rua,
   en.nm_bairro,
   en.nm_cidade,
   en.sg_estado,
   en.nm_pais,
   en.nr_cep,
   en.ds_complemento,

   ba.cd_agencia,
   ba.nm_agencia, 
   ba.nm_banco,
   ba.cd_banco,
   ba.nr_carteira,
   ba.nr_conta_corrente,

   ca.cd_campanha,

   ep.nm_empresa

from 
	boleto_bancario bb , pagamt_agendado pa, 
   pedido pe, cliente cl, endereco en, banco ba, 
   campanha ca ,uo , empresa ep

where
   pa.id_boleto_bancario = bb.id_boleto_bancario and
   bb.id_endereco = en.id_endereco and
   pa.id_pedido = pe.id_pedido and
   pe.id_cliente = cl.id_cliente and
   bb.ID_BANCO = ba.id_banco and
   pe.id_campanha = ca.id_campanha and
   pa.tp_pagamt_agendado ='BB' and
   uo.id_uo = ba.id_uo and
   uo.id_empresa =  ep.id_empresa
 
