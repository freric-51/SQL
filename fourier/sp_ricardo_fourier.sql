create or replace procedure SP_RICARDO_FOURIER is

-- Nomenclatura das variáveis tiradas página 388 do livro Cálculo Avançado
   type A is varray(31) of number;
--
   L double precision;
   Harmonico number;
   Harmonicas number;
   Ponto_Agora double precision;
   Ponto double precision;
   Inicio double precision;
   Soma_A double precision;
   Soma_B double precision;
   Zant_A double precision;
   Zant_B double precision;
   Zatu_A double precision;
   Zatu_B double precision;
   Zcosseno double precision;
   Zseno double precision;
   x double precision;
   DX double precision;
   Ax A := A(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
   Bx A := A(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
   PI double precision ;
   Qtd_Pontos number;

   cursor FX is
      select Triangular
      from fourier_ondas_previsao
      where nr_ponto >= Inicio
      and   nr_ponto <= Ponto_Agora
      order by nr_ponto;
--
begin
     update fourier_ondas_previsao set 
     Quadrada_Previsao = null ,
     Triangular_Previsao = null ,
     Serra_Previsao = null;
     
--   SP_FOURIER_PASSO01(to_date('31/03/2004 11:00:00', 'dd/mm/yyyy hh24:mi:ss'),'111','Y01');
--
   PI := acos(-1) ;
   Harmonicas := 21;-- se harmonicas > 30 then erro !
   Ponto_Agora := 671; 
   Inicio := 0;
--
   select count (*) into Qtd_Pontos 
   from fourier_ondas_previsao
   where nr_ponto >= Inicio
   and   nr_ponto <= Ponto_Agora ;
   
   L:= PI  ;  -- *(Qtd_Pontos / 96);
   DX := 2 * L / Qtd_Pontos;

-- calculo das constantes
 
      Harmonico := 0;
      loop -- de Harmonico
         Soma_A := 0;
         Soma_B := 0;

         x := - L;
         Zant_a := 0;
         Zant_b := 0;
            for tmp in FX loop
               Zcosseno := cos(Harmonico * PI * x / L);
               Zatu_a := tmp.Triangular * Zcosseno;
               
               Zseno := sin(Harmonico * PI * x / L);
               Zatu_b := tmp.Triangular * Zseno;
               
               Soma_A := Soma_A + ( 0.5 * DX * ( Zant_a + Zatu_a ));
               Zant_a := Zatu_a ;
                                            
               Soma_B := Soma_B + ( 0.5 * DX * ( Zant_b + Zatu_b ));
               Zant_b := Zatu_b ;
               
               x := x + DX;
            end loop;    -- cursor tmp

         Ax(Harmonico + 1) := 1/L * Soma_A;
         Bx(Harmonico + 1) := 1/L * Soma_B;
         Harmonico := Harmonico + 1;
      exit when Harmonico > Harmonicas;
      end loop;   --   next Harmonico

-- previsao 
   x := - L;
   Ponto := 0 ;
   loop -- de X
      
      Soma_A := 0;
      Harmonico:=1;
      loop  -- de Harmonico
         Soma_A := Soma_A + ax(harmonico + 1) * cos(Harmonico * PI * x / L);
         Soma_A := Soma_A + bx(harmonico + 1) * sin(Harmonico * PI * x / L);
         Harmonico := Harmonico + 1;
         exit when Harmonico > Harmonicas;
      end loop;

      Soma_A := Soma_A + ax(0 + 1)/2 ;
      update fourier_ondas_previsao set Triangular_Previsao =  Soma_A where nr_ponto = inicio + Ponto;
      Ponto := Ponto + 1 ;
      x := x + DX;
      exit when x > L;
   end loop;
   

end SP_RICARDO_FOURIER;
