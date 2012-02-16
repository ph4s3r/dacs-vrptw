%ACS-TIME
function [Global_Best_TC] = ACS_Time(ACSV_phermones, ACSV_fleet, ACSV_TC, stopeval, n, distance_matrix, customer_demands, vehicle_cap, load_time, TimeWindow, varargin)

%Input parameterek
	p = inputParser;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
	p.addOptional('num_of_ants', 33);
    %feromon vs attraction kiegyensulyozasara
	p.addOptional('beta', 1);
    %feromon parolgasi tenyezo (globalis)
	p.addOptional('gamma', .3);
    %feromon parolgasi tenyezo (lokalis)
    p.addOptional('rho', .3);
    %Mennyi esellyel valasztjuk a legjobb ugyfelet
    p.addOptional('q0', .9);
	p.parse(varargin{:});

	num_of_ants = p.Results.num_of_ants;
	rho = p.Results.rho;
	beta = p.Results.beta;
    gamma = p.Results.gamma;
    q0 = p.Results.q0;

    clear varargin

evalcount = 1;

depot = 1;

Global_Best_TC = Inf;

%A feromon matrixot atvesszuk az ACS_Vehicle-bol
pheromones = ACSV_phermones;

%Azert kell, mert lehet hogy meg az elso korben nem lesz Gbest
Global_Best_Solution_Index = 1;

 %%%%%%%%%%%%%%%%%%%%%%%%%%%
 while evalcount < stopeval
 %%%%%%%%%%%%%%%%%%%%%%%%%%%
 Infeasibles = zeros(1,num_of_ants);
 for ki=1:num_of_ants
 tours_el{ki} = NaN(n,2);
 end
 clear ki
 if(evalcount > 1)
    tours_el{Global_Best_Solution_Index} = Best_Edges;
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %Minden antra lefuto ciklus
      for k = 1:num_of_ants
          k = k + 1; %#ok<FXSET>
          %Egy ant hanyadik jarmûvet inditja
          ant_priv_vehicle_num = 0;
          %Egy ant altal bejart node-ok iteratora
          ant_tour_len = 1;
          %Minden ant sajat feromon es attraction ertekkel dolgozik, a pheromone
          %csak a local/global update-el valtozik
          private_pheromones = pheromones;

              %Egy ant osszes jarmûve ebben a ciklusban fut le

              while(ant_priv_vehicle_num < ACSV_fleet)

                  %Kulon jarmû inditasa
                  ant_priv_vehicle_num = ant_priv_vehicle_num + 1;
                  %Mikor indulhat
                  cur_time = 6;
                  attraction = ones(n,n);

                  %Ha mar kiszallitottunk mindent, vege a munkaidonek:)
                  %9/10 az eselye hogy nem akkor lepunk ki, mikor egy jarmu
                  %az osszes arut kiszallitotta
                  if(ant_tour_len >= n)
                      break
                  end
                  %A jarmûben mennyi szallitmany van
                      current_vehicle_cap = vehicle_cap; %Q alapertekre visszaallitjuk
                      %elso megallo a depo
                      last_node = depot;
                      %egy jarmu hanyadik megallojanal tart
                      customer_seq = 1;

                      %A depobol hova erdemes eppen most menni
                      for j = 2:n
                          m123 = max(cur_time + distance_matrix(last_node,j), TimeWindow(j,1));
                          ncur = 1.0/((m123 - cur_time) * (TimeWindow(j,2) - cur_time) ); %- IN(j)
                          attraction(last_node,j) = ncur;
                      end

                      path(customer_seq) = depot; %#ok<*SAGROW>
                  while(current_vehicle_cap > 0)

                      %Ha mar meglatogattuk az osszes varost, kilephetunk
                      if(ant_tour_len >= n)
                        break
                      end
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     %Kivalasztasa a kovetkezo node-nak:
                     %Kozelseg-ertekek
                     private_pheromones_x_attraction =  private_pheromones.^1 .* attraction.^beta;
                     %Az eppeni helyunkrol hova lehet menni egyaltalan,es
                     %milyen valoszinuseggel
                     current_node_attraction_scores = private_pheromones_x_attraction(last_node,:);
                     %A depoba nem megyunk kozvetlenul
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
              %Lokalis feromon update: (0,9x)
                  pheromones(last_node,current_node) = (1 - rho)*private_pheromones(last_node,current_node);
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
                               attraction(j,last_node) = 0;
                          else
                              m123 = max(cur_time + distance_matrix(last_node,j), TimeWindow(j,1));
                              ncur = 1.0/((m123 - cur_time) * (TimeWindow(j,2) - cur_time));                           
                              attraction(last_node,j) = ncur;
                              attraction(j, last_node) = ncur;
                          end
                      end
                      clear j dist
                      %Minden, mar meglatogatott node elerhetetlen
                      attraction(last_node, last_node) = 0;
                      %Minden, mar meglatogatott node feromonja nulla
                      private_pheromones(:,last_node) = 0;
                  end

                  path(customer_seq + 1) = depot;
                  %Elmentjuk az adott jarmu utvonalat
                  tours{ant_priv_vehicle_num} = path(:)';
                  %warps{ant_priv_vehicle_num} = timepath(:,:);
                  clear path timepath

              end
                 EdgeList(ant_tour_len,1) = last_node; %#ok<*AGROW>
                 EdgeList(ant_tour_len,2) = depot;
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              %Egy ant osszes jarmuve beerkezett: van egy megoldasunk
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              %Megvizsgaljuk, hogy ervenyes-e a megoldas:
              if(ant_tour_len < n)
                  Infeasibles(k-1) = 1;
                  currentAntTCs(k-1) = Inf; %nem lehet 0, mert minimumot keresunk a legjobbnak
                  clear tours
              else
                  %Csak akkor erdekel a megoldas, ha feasible
                  %eppeni ant megoldasanak kimentese (ellista)
                  tours_el{k-1} = EdgeList(:,:);
                  %eppeni ant megoldasanak kimentese (matlog loc-seq struktura)
                  [AntTC,AntFlg,Antout] = locTC(tours,distance_matrix,{customer_demands,vehicle_cap},{load_time,TimeWindow});
                  currentAntTCs(k-1) = sum(AntTC);
                  clear tours
              end
              clear EdgeList
                  
                  
      end %Minden antra lefuto for ciklus vege: Itt minden ant rendelkezik megoldassal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Csak a feasible megoldasok kozul vesszuk ki a legjobb TC elemet
%currentAntTC = Inf infeasible megoldas eseten
if(min(currentAntTCs) < Inf)
    isfeasfound_eval = 1;
else
    isfeasfound_eval = 0;
end
[Global_Best_TCi, Global_Best_Solution_Indexi] = min(currentAntTCs);
if (Global_Best_TCi < Global_Best_TC)
    Global_Best_TC = Global_Best_TCi;
    Global_Best_Solution_Index = Global_Best_Solution_Indexi;
end

%a tours_el valtozot mindig toroljuk, de a legjobb megoldast elmentjuk
Best_Edges = tours_el{Global_Best_Solution_Index};
%**********************************
    %Globalis feromon update: (Lgb)
    %csak vegig kell menni a legjobb megoldas ellistajan, es a feromon
    %matrixban ezen eleket updatelni
    if(isfeasfound_eval)
       for gi = 2:n
            i = tours_el{Global_Best_Solution_Index}(gi,1);
            j = tours_el{Global_Best_Solution_Index}(gi,2);
            pheromones(i,j) = (1-gamma)*pheromones(i,j) + gamma/(Global_Best_TC*n);
            pheromones(j,i) = (1-gamma)*pheromones(j,i) + gamma/(Global_Best_TC*n);
        end
    end
        clear gi i j tours_el
    %Globalis feromon update end
%*******************************
          evalcount = evalcount + 1;
          eval_best(evalcount-1) = Global_Best_TC;
          %Infeasibles_per_eval(evalcount-1) = sum(Infeasibles);

          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear ACSV_TC ACSV_phermones AntFlg AntTC Antout 
clear Global_Best_Solution_Indexi Global_Best_TCi Infeasibles ant_priv_vehicle_num 
clear ant_tour_len attraction best_customer cumsum_step_probabilities cur_time currentAntTCs 
clear current_node current_node_attraction_scores current_vehicle_cap customer_seq diffs 
clear last_node m123 ncur p isfeasfound q r 
clear private_pheromones private_pheromones_x_attraction step_probabilities tours_el        

%%%%
end%
%%%%
clear Global_Best_TC
Global_Best_TC = eval_best;