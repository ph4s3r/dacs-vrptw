function [ACSV_fleet, Most_Goods_TC, pheromones] = ACS_Vehicle(fleet_max , Initial_TC, n, distance_matrix, customer_demands, vehicle_cap, load_time, TimeWindow, varargin)
%AS-VEHICLE
  
    %Input parameterek
	p = inputParser;
	p.addOptional('num_of_ants', 33);
    %feromon vs attraction kiegyensulyozasara
	p.addOptional('beta', 1);
    %feromon parolgasi tenyezo (globalis)
	p.addOptional('gamma', .3);
    %feromon parolgasi tenyezo (lokalis)
    p.addOptional('rho', .3);
    %Mennyi esellyel valasztjuk a legjobb ugyfelet
    p.addOptional('q0', .6);
	p.parse(varargin{:});
    
	num_of_ants = p.Results.num_of_ants;
	rho = p.Results.rho;
	beta = p.Results.beta;
    gamma = p.Results.gamma;
    q0 = p.Results.q0;
    
      %A feromon-inithez kene a greedy altal adott tau0 = 1/n*sum(TC), ahol
      %n = varosok szama, sum(TC) pedig a greedy altal adott Total Cost ertek
      %Ezt a Total Cost-ot most a cw-savings altal adott TC-bol vehetjuk
      
      tau0 = 1/(n*Initial_TC);

      Most_Goods_TC = Initial_TC;
      ASV_Best_TC = Initial_TC;
      ASV_Best_Solution_Index = Inf;
      Most_Goods_length = 0;
      %A legjobb megoldas Infeasible v nem
      Lmg = NaN;
      
      %tau0 lesz a feromon matrix osszes erteke
      pheromones = ones(n,n) * tau0;

      %depo varos indexe
      depot = 1;

      %Egy kliensre hanyszor 'nem esett' valasztas
      IN = zeros(1,n);
      %tavolsagok keplet acs-vrptw-xuan szerint
      attraction = ones(n,n);
       %alg. iterator: hanyszor futott le az egesz alg.
       evalcount = 1;
       %Mikor elerjuk, hogy minden megoldas infeasible,
       %megprobaljuk meg 2x ezzel a flottaszammal
       reeval = 2;

 %%%%%%%%%%%%%%%%%%%%%%%%%%%
 while 1 %megallasi kriterium utan allunk le
 %%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 Infeasibles = zeros(1,num_of_ants);
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %Minden antra lefuto ciklus
      for k = 1:num_of_ants
          k = k + 1; %#ok<FXSET>
          %Egy ant hanyadik jarmûvet inditja
          ant_priv_vehicle_num = 0;
          %Egy ant altal bejart node-ok iteratora
          ant_tour_len = 1;
          %Minden ant sajat feromon ertekkel dolgozik
          private_pheromones = pheromones;

              %Egy ant osszes jarmûve ebben a ciklusban fut le

              while(ant_priv_vehicle_num < fleet_max)
                  
                  %Kulon jarmû inditasa
                  ant_priv_vehicle_num = ant_priv_vehicle_num + 1;
                  %Mikor indul
                  cur_time = 6;

                  %Ha mar kiszallitottunk mindent, vege a munkaidonek:)
                  %9/10 az eselye hogy nem akkor lepunk ki, mikor egy jarmu
                  %az osszes arut kiszallitotta
                  if(ant_tour_len >= n)
                      break
                  end
                  %A jarmûben mennyi szallitmany van
                      current_vehicle_cap = vehicle_cap; %Q = 100-re visszaallitjuk
                      %elso megallo a depo
                      last_node = depot;
                      %egy jarmu hanyadik megallojanal tart
                      customer_seq = 1;

                      %A depobol hova erdemes eppen most menni
                      for j = 2:n
                          m123 = max(cur_time + distance_matrix(last_node,j), TimeWindow(j,1));
                          ncur = 1.0/((m123 - cur_time) * (TimeWindow(j,2) - cur_time) - IN(j));
                          attraction(last_node,j) = ncur;
                      end

                      path(customer_seq) = depot; %#ok<*SAGROW>
                  while(current_vehicle_cap > 0)

                      %Ha mar meglatogattuk az osszes varost, kilephetunk
                      if(ant_tour_len >= n)
                        break
                      end
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     %Kivalasztasa a kovetkezo node-nak
                     private_pheromones_x_attraction = private_pheromones.^1 .* attraction.^beta;

                     current_node_attraction_scores = private_pheromones_x_attraction(last_node,:);
                     current_node_attraction_scores(1,1) = 0;
      				 %pij keplet = cnas/sum(cnas)
                     step_probabilities = current_node_attraction_scores ./ sum(current_node_attraction_scores);

                     %bizonyos valoszinuseg szerint vagy a legjobbat, vagy
                     %a pij keplet szerint valasztunk kovetkezo csucsot
                     cumsum_step_probabilities = cumsum(step_probabilities);
                     q = rand();
                     [C, best_customer] = max(step_probabilities);
                     clear C
                     %Ha nincs mar elerheto varos, kilephetunk
                     if (best_customer == depot) 
                             break
                     end
                     if (q < q0)
                         current_node = best_customer;
                     else 
                         current_node = 2;
                         r = rand() * cumsum_step_probabilities(n);
                         while (cumsum_step_probabilities(current_node) < r)
                            current_node = current_node + 1;
                         end
                     end 

      %**************************
      %Lokalis feromon update:
          pheromones(last_node,current_node) = (1 - rho)*private_pheromones(last_node,current_node) + rho*tau0;
      %Lokalis feromon update end
      %**************************

                     %Vagy varni kell a nyitasig, vagy nem, vagy nem is
                     %erunk oda nyitasra
                     if(cur_time + distance_matrix(last_node,current_node) < TimeWindow(current_node, 1)) 
                         cur_time = TimeWindow(current_node, 1);
                     else
                     cur_time = cur_time + distance_matrix(last_node, current_node) ;
                     end
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     customer_seq = customer_seq + 1;
                     ant_tour_len = ant_tour_len + 1;
                     %A kiszolgalt ugyfel bekerul az utat tarolo tombbe 
                     path(customer_seq) = current_node;
                     %Teljes ant ut ellistas tarolasa
                     EdgeList(ant_tour_len-1,1) = last_node;
                     EdgeList(ant_tour_len-1,2) = current_node;
                     %erkezesi ido + TW

                     %timepath(customer_seq,1) = distance_matrix(last_node,current_node);
                     %timepath(customer_seq,2) = cur_time;
                     %timepath(customer_seq,3) = cur_time + load_time;
                     %timepath(customer_seq,4) = TimeWindow(current_node,1);
                     %timepath(customer_seq,5) = TimeWindow(current_node,2);
                     cur_time = cur_time + load_time;
                     %Kipakolas
                     current_vehicle_cap = current_vehicle_cap - customer_demands(current_node);

                     last_node = current_node;
                     %Az eppeni megallobol barmelyik masikba mennyire
                     %erdemes eppen most menni
                      for j = 1:n
                          %Ha mar bezart, nem tudunk menni
                          dist = distance_matrix(last_node, j);
                          if (cur_time +  dist + load_time > TimeWindow(j,2))
                               attraction(last_node,j) = 0;
                          else
                              m123 = max(cur_time + distance_matrix(last_node,j), TimeWindow(j,1));
                              ncur = 1.0/((m123 - cur_time) * (TimeWindow(j,2) - cur_time) - IN(j));                             
                              attraction(last_node,j) = ncur;
                          end
                      end
                      clear j C dist q r
                      %Minden, mar meglatogatott node elerhetetlen
                      attraction(last_node, last_node) = 0;
                      %Minden, mar meglatogatott node feromonja nulla
                      private_pheromones(:,last_node) = 0;
                  end

                  path(customer_seq + 1) = depot;
                  %Elmentjuk az adott jarmu utvonalat
                  tours{ant_priv_vehicle_num} = path(:)';
                  %warps{ant_priv_vehicle_num} = timepath(:,:);
                  clear path

              end
                 EdgeList(ant_tour_len,1) = last_node; %#ok<*AGROW>
                 EdgeList(ant_tour_len,2) = depot;
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              %Egy ant osszes jarmuve beerkezett: van egy megoldasunk
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              %Megvizsgaljuk, hogy ervenyes-e a megoldas:
              goods(k-1) = ant_tour_len;
              if(ant_tour_len < n)
                  Infeasibles(k-1) = 1;
                  currentAntTCs(k-1) = Inf; %Minimumkeresesnel ez az ertek jo nagy kell legyen

              end
              %eppeni ant megoldasanak kimentese (ellista)
              tours_el{k-1} = EdgeList(:,:);
              %eppeni ant megoldasanak kimentese (matlog loc-seq struktura)
              [AntTC,AntFlg,Antout] = locTC(tours,distance_matrix,{customer_demands,vehicle_cap},{load_time,TimeWindow});
              currentAntTCs(k-1) = sum(AntTC);
              clear tours Antout AntTCs
              %IN tombben minden csomoponthoz taroljuk, amely nem lett kivalasztva
              %egy ant ut alatt, hogy nem lett kivalasztva
              if(Infeasibles(k-1) == 1)
                diffs = setxor(unique(EdgeList),1:n);
                for i=1:length(diffs)
                    IN(diffs(i)) = IN(diffs(i)) + 1;
                end
              end
              clear EdgeList
                
      end %Minden antra lefuto for ciklus vege: Itt minden ant rendelkezik megoldassal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    %Ha nincs Infeasible, akkor a legjobb TC kell
    if(max(Infeasibles) == 0)
        [ASV_Best_TCi, ASV_Best_Solution_Indexi] = min(currentAntTCs);
        Lmg = 0;
    else
        %A leghosszabb megoldas kell, ha csak Infeasible van,
        [Most_Goods_lengthi, Most_Goods_Indexi] = max(goods);
        %Ha tobb leghosszabb van, azokbol a legjobb TC
        [r,c,v] = find(goods > Most_Goods_lengthi-1);
        min_infeas_maxgood_TC = currentAntTCs(Most_Goods_Indexi);
        for ci=1:length(c)
            %c-ben van a tobb egyhosszu megoldas indexe, pl.
            %1 2 3 6 11 12 20 stb...
            min_infeas_maxgood_TCi = currentAntTCs(c(ci));
            if(min_infeas_maxgood_TCi < min_infeas_maxgood_TC)
                min_infeas_maxgood_TC = min_infeas_maxgood_TCi;
                Most_Goods_Indexi = c(ci);
                Most_Goods_lengthi = goods(c(ci));
            end
        end
        Lmg = 1;
    end

%**********************************
    %Globalis feromon update: (Lmg) vagy (Lgb)

    %Ha ebben az eval-ban jobb megoldast talaltunk, mint eddig volt:
if(Lmg == 1)
        %Ha hosszabb mint az eddigi leghosszabb
        if(Most_Goods_lengthi > Most_Goods_length)
            IN = zeros(1,n);
            Most_Goods_length = Most_Goods_lengthi;
            Most_Goods_Index = Most_Goods_Indexi;
            Most_Goods_TC = currentAntTCs(Most_Goods_Index);
            %Vagy ugyanolyan hosszu
        elseif(Most_Goods_lengthi == Most_Goods_length)
            %, de jobb TC
            if(currentAntTCs(Most_Goods_Indexi) < Most_Goods_TC)
            Most_Goods_length = Most_Goods_lengthi;
            Most_Goods_Index = Most_Goods_Indexi;
            Most_Goods_TC = currentAntTCs(Most_Goods_Indexi);
            end

        end
    %csak vegig kell menni a legjobb megoldas ellistajan, es a feromon
    %matrixban ezen eleket updatelni
    if ( Most_Goods_length == Most_Goods_lengthi && Most_Goods_Index == Most_Goods_Indexi) %Ha ebben az iteracioban jobb megoldast talaltunk.
        for gi = 2:Most_Goods_length
           i = tours_el{Most_Goods_Index}(gi,1);
            j = tours_el{Most_Goods_Index}(gi,2);
            pheromones(i,j) = (1-gamma)*pheromones(i,j) + gamma*1/(Most_Goods_TC*n);
            pheromones(j,i) = (1-gamma)*pheromones(j,i) + gamma*1/(Most_Goods_TC*n);
       end
    end
        clear gi i j
elseif(Lmg==0 && ASV_Best_Solution_Index < Inf)
    if (ASV_Best_TCi < ASV_Best_TC)
    IN = zeros(1,n);
    ASV_Best_TC = ASV_Best_TCi;
    ASV_Best_Solution_Index = ASV_Best_Solution_Indexi;
    end
        if ( ASV_Best_TC == ASV_Best_TCi) %Ha ebben az iteracioban jobb megoldast talaltunk.
            for gi = 2:n
                i = tours_el{ASV_Best_Solution_Index}(gi,1);
                j = tours_el{ASV_Best_Solution_Index}(gi,2);
                pheromones(i,j) = (1-gamma)*pheromones(i,j) + gamma*1/(ASV_Best_TC*n);
                pheromones(j,i) = (1-gamma)*pheromones(j,i) + gamma*1/(ASV_Best_TC*n);
            end
        end
        clear gi i j
end
    %Globalis feromon update end
%*******************************

          evalcount = evalcount + 1;
          clear last_node current_node tours_el
          eval_best(evalcount-1) = min(Most_Goods_TC,ASV_Best_TC);
          Infeasibles_per_eval(1,evalcount-1) = sum(Infeasibles);
          Infeasibles_per_eval(2,evalcount-1) = fleet_max;
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

          if(min(Infeasibles) == 1)
              %Ha csak infeasible van, ennyi jarmu biztosan keves, eggyel
              %tobb viszont meg jo volt!
              reeval = reeval - 1;
              if(reeval == 0)
              eval_resp = sprintf('Az ACS_Vehicle %d kiertekeles utan %d jarmuvet talalt a minimumnak', evalcount, fleet_max + 1);
              disp(eval_resp);
              clear eval_resp
                break;
              end
          else
              %Fleet num csokkentese, mert vannak meg jo megoldasok
              fleet_max = fleet_max - 1;
          end

 %%%%
 end%
 %%%%

 %+1-et kell visszaadni, mert az utolso flottaszammal nem voltak mar jo
 %megoldasok..
 Most_Goods_TC = eval_best;
 ACSV_fleet = fleet_max + 1;
 
 clear private_pheromones_x_attraction private_pheromones vehicle_cap tau0 
 clear step_probabilities attraction k m123 ncur ans customer_seq
 clear beta gamma rho cur_time B ant_priv_vehicle_num best_customer depot
 clear num_of_ants evalcount stopeval n load_time ant_tour_len fleet_num distance_matrix customer_demands 
 clear cumsum_step_probabilities current_node_attraction_scores current_vehicle_cap