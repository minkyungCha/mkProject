/*TWISTBONES

Version 1.7
Author: Felix Joleanes
web:    www.joleanes.co
email:  felix@joleanes.com

utilidad para crear automaticamente los twistbones (TBs) de todas las extremidades
para un biped standard de max
la utilidad crea un TB principal con un rotation_script controller necesario para su funcionamiento
y varios TBs extras con orientation constraints desde el TB Principal hacia la extremidad respectiva, con
pesos respectivos a su posicion en la jerarquia de TBs


Modificacion version 1.6:
Se mejoro la ecuacion que halla el valor de compensacion el eje x para evitar el flipping del gimbal lock
ahora ya no existen los flipping que tenia la anterior version en siertos angulos, y ademas el hombro
mantiene una ubicacion mas correcta

Modificacion version 1.7:
el valor de rotacion del TB que evita heredar la rotacion del eje x de la extremidad ahora se halla
por medio de la construccion del quaternion de rotacion, de esta forma el resultado será más preciso.
*/

macroScript twistbones
	category:"Custom tools"
	icon:#("Radiosity", 3)
(
rollout TBPersiana "Twist Bones"
(
 --Aqui se define la funcion que desarrolla todos los procedimientos necesarios para crear los twistbones
 --tomando como argumento un arreglo n con cuatro variables definiendo la cantidad de twistbones por cada extremidad
 --n=#(nBrazo,nAntebrazo,nMuslo,nPantorrilla)
 --realiza esto tomando todos los bipedos de la escena
 function TBSetFunction n=
 (
  --establesco algunas variables
  bipRoots=#()--arrreglo donde guardo todos los bips seleccionados de la escena
  bipLimbs=#()--arreglo que utilizo en un bucle para conocer que parte del bipedo esta siendo usada para crear los twistbones
  --se definen las variables que utilizare en la funcion biped.getNode para obtener la instancia respectiva al objeto siendo 
  --procesado, ademas defino una bandera que dice si se trata de una operacion inversa al algoritmo estandar usado en el hombro,
  --es falso si se trata del antebrazo o la pantorrilla.
  bipLimbs[1]=#(#larm,2,n[1],1," L UpperArm")
  bipLimbs[2]=#(#rarm,2,n[1],1," R UpperArm")
  bipLimbs[3]=#(#larm,3,n[2],2," L ForeArm")
  bipLimbs[4]=#(#rarm,3,n[2],2," R ForeArm")
  bipLimbs[5]=#(#lleg,1,n[3],3," L Thigh")
  bipLimbs[6]=#(#rleg,1,n[3],3," R Thigh")
  bipLimbs[7]=#(#lleg,2,n[4],4," L Calf")
  bipLimbs[8]=#(#rleg,2,n[4],4," R Calf")
  
  --Las TBExpression son las expreciones de los script controllers de los TBs principales
  --una para cada par de extremidades (brazos, antebrazos...etc)
  
  --La Expresion A es para el Brazo-Hombro.
  --ya que el TB principal de esta zona esta vinculado al Brazo, este tendra 
  --que heredar solo los valores de rotacion en los ejes Y y Z del brazo, y el 
  --eje X lo heredara del hombro a partir de la ecuacion definida en el valor X del script controller
  --en el controlador no podemos dejar simplemente X en -X para compensar la rotacion,
  -- ya que existiria un flip en el TB superados los 90 o -90 grados con respecto al hombro sobre el eje Y,
  --debido a la falta de compesacion del gimbal Lock generados entre el eje X y Z.
  --para mejorar esto, utilizo el eje Z para compensar al eje X a travez con Y como multiplicador 
  --para que Z solo actue en X en angulos donde se necesite esta compensacion. asi no solo se evita el flip, 
  --si no que tambien el TB adopta posiciones adecuadas segun la rotacion del brazo, y cambios graduales
  --entre estas posiciones. Tambien se define un divisor en este resultado para ajustar los valores de compensacion
  --en los angulos adecuados
  TBExpressionA="try(
TM=Limb.transform*inverse Limb.parent.transform
vector=normalize (cross TM.row1 [1,0,0])
angle=acos (normalize TM.row1).x
(quat angle vector)*inverse TM.rotation)
 catch((quat 0 0 0 1))"
  
  --La expresion B es para el AnteBrazo-mano, Ba para la mano derecha y Bb para la izquierda
  --el sistema es muy similar al del brazo-hombro, solo que aqui el valor de x es multiplicado por -1
  --esto ya que en este caso no se trata de bloquear la rotacion heredada, si no adquirir la rotacion
  --de otro nodo, ademas se utiliza un offset de 90 grados para retrasar el flipping de los TBs extra
  TBExpressionBa="try(
TM=(matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0])*Limb.transform*inverse Limb.parent.transform
vector=normalize (cross TM.row1 [1,0,0])
angle=acos (normalize TM.row1).x
TM.rotation*(quat -angle vector))
 catch((quat 0 0 0 1))"
  TBExpressionBb="try(
TM=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])*Limb.transform*inverse Limb.parent.transform
vector=normalize (cross TM.row1 [1,0,0])
angle=acos (normalize TM.row1).x
TM.rotation*(quat -angle vector))
 catch((quat 0 0 0 1))"

  
  --La expresion C es para la Pierna-Pelvis.
  --esta expresion es practicamente la misma del Brazo-Hombro, pero ya que
  --la orientacion neutral de la pierna con respecto a la pelvis es 180 grados
  --distinta a la del brazo-hombro, se debe rotar sobre el eje Z 180 grados
  --antes de ejecutar el calculo del valor de compensacion en X, y luego rotarlos
  --de nuevo en direccion opuesta para dejarlo en la posicion original
  TBExpressionC="try(
TM=Limb.transform*inverse Limb.parent.transform
vector=normalize (cross -TM.row1 [1,0,0])
angle=acos -(normalize TM.row1).x
(quat 0 1 0 0)*(quat angle vector)*inverse TM.rotation)
catch((quat 0 0 0 1))"
  
  TBExpressionD="try(
TM=Limb.transform*inverse Limb.parent.transform
vector=normalize (cross TM.row1 [1,0,0])
angle=acos (normalize TM.row1).x
TM.rotation*(quat -angle vector))
 catch((quat 0 0 0 1))"

  
  --Las TBExtraExpression son las expreciones de los script controllers de los TBs extras
  --una para las extremidades primarias (brazos,muslos) y otra para las extremidades
  --secudarias (antebrazos,pantorrillas)
  
  --en esta expresion se obtiene la orientacion de la extremidad con respecto al
  --TB. Junto con un valor apropiado en el weight de este controlador, se logra
  --un valor intermedio entre la extremidad y el TB. para todos los Tbs extras en la
  --cadena se utiliza el mismo weight(el cual depende del numero de Tbs extra), 
  --ya que al estar vinculado un TB extra al otro este primero acumula las rotaciones
  --de todos los anteriores mas la suya y de esta forma se aproxima cada ves mas
  --a la orientacion de la extremidad.
  --Esto es lo mismo que tener un orientation constraint con pesos relativos
  --a la posicion de los TBs extra en la cadena, pero con el metodo de scripts, 
  --si son muchos huesos extra, todos tendran referencia a un mismo controlador, 
  --lo cual a mi parecer es mas optimo que tener un controlador de orientacion 
  --distinto por cada TB extra con sus propios pesos.
  TBExtraExpressionA="try(
(Limb.transform*inverse LimbParent.transform).rotation
)catch((quat 0 0 0 1))"
  
  --este es similar al anterior pero aqui el script obtiene el valor del controlador
  --del TB principal en vez del valor de la rotacion de la extremidad con respecto al TB
  TBExtraExpressionB="try(dependson TB
TB.rotation.controller[1].value
)catch((quat 0 0 0 1))"

  --en este bucle hallo todos los bips raices y los almaceno en el arreglo bipRoots
  for i in selection do
  (
   if (classof i.controller==BipSlave_Control) then
   (
		if (finditem bipRoots i.controller.rootnode)==0 then
			append bipRoots i.controller.rootnode
   )
   else if (classof i.controller==Vertical_Horizontal_Turn) then
   (
	   if (finditem bipRoots i)==0 then
			append bipRoots i
   )
   
  )
  
  --aqui empieza el bucle en donde se crean los TBs en todos los bipeds de la escena
  --arrancando con un "undo on" para encerrar todas los procesos en una sola operacion que se pueda deshacer
  --facilmente
  for i in bipRoots do
  (
   --bucle que corre a travez de todas las extremidades donde se crean los TBs
   RLegAux=biped.getNode i #Rleg link:1
   LLegAux=biped.getNode i #Lleg link:1
   PelvisAux=biped.getNode i #pelvis
   
   RLegAux.parent=LLegAux.parent=PelvisAux

   for k in bipLimbs do
   (
    if (k[3]>0) then
	(
    Limb=biped.getNode i k[1] link:k[2] --obtengo la instancia de la extremidad a partir de las dos primeras variables del arreglo actual
	distanceVar=(distance limb limb.Children[1]) --longitud de la extremidad
	
	--defino algunas variables 
	TBExpression=""
	ControllerLimb=Limb
	weightVar=100
	--se decide cual sera la expresion del script que va a tener la extremidad actual
	--ademas de su cantidad de influencia (weight), y sus variables limb y limbparent
	case k[4] of
	(
	 1:(TBExpression=TBExpressionA)
	 2:(
	    if k[1]==#larm then TBExpression=TBExpressionBb else TBExpression=TBExpressionBa
		ControllerLimb=Limb.children[1]
		weightVar=100/k[3]
	   )
	 3:(TBExpression=TBExpressionC)
	 4:(
	    TBExpression=TBExpressionD
		ControllerLimb=Limb.children[1]
		weightVar=100/k[3]
	   )
	)
	
	--creo el TB principal, defino su nombre, su padre, sus caracteristicas geometricas, y le asigno su script controller
	--respectivo, con sus variables respectivas
    TwistBone=BoneSys.createBone Limb.transform.position Limb.transform.position [0,0,1] 
	TwistBone.name="Bone"+k[5]+" Twist"
    TwistBone.parent=Limb
    TwistBone.Length=distanceVar/k[3]
    TwistBone.Width=distanceVar/8
    TwistBone.Height=TwistBone.Width
	TwistBone.taper=0
	TwistBone.rotation.controller=Rotation_List()
    TwistBone.rotation.controller[1].controller=rotation_script()
    TwistBone.rotation.controller[1].AddNode "Limb" ControllerLimb
    TwistBone.rotation.controller[1].SetExpression TBExpression
	TwistBone.rotation.controller.weight[1]=weightVar
	
    --creo el script controller que van a tener las rotaciones de los TBs extras,
    --es distinto el de los brazos y muslos al de los antebrazos, pantorrillas
	TBExtraController=rotation_script()
	case of
	(
	 (k[4]==1 or k[4]==3):(
	                       TBExtraController.AddNode "Limb" Limb 
	                       TBExtraController.AddNode "LimbParent" TwistBone 
	                       TBExtraController.setExpression TBExtraExpressionA
						  )
	 (k[4]==2 or k[4]==4):(
	                       TBExtraController.AddNode "TB" TwistBone
	                       TBExtraController.setExpression TBExtraExpressionB
						  )
	)
	PrevTBE=TwistBone
	--el bucle donde se crean los TBs extras
    --por cada uno se define una posicion, el padre (el TB extra anterior, y si es el primero, se utiliza el TB principal) 
	--caracteristicas geometricas, y se le asigna a cada uno como rotation controller el TBExtraController
    for j=2 to k[3] do
    (
     TwistBoneExtra=BoneSys.createBone [0,0,0] [1,0,0] [0,0,1] 
	 matAux=matrix3 1
	 matAux.position=[(distanceVar/k[3]),0,0]
	 TwistBoneExtra.transform=matAux*PrevTBE.transform
	 TwistBoneExtra.name=TwistBone.name+((j-1) as string)
	 TwistBoneExtra.parent=PrevTBE
	 TwistBoneExtra.Length=distanceVar/k[3]
     TwistBoneExtra.Width=PrevTBE.Width
     TwistBoneExtra.Height=PrevTBE.Height
	 TwistBoneExtra.taper=0
	 TwistBoneExtra.rotation.controller=Rotation_List()
	 TwistBoneExtra.rotation.controller[1].controller=TBExtraController
	 TwistBoneExtra.rotation.controller.weight[1]=100/k[3]
	 PrevTBE=TwistBoneExtra
    )
	)
   )
  )
 )
 --Aqui ya empiezo a crear los controles graficos de la utilidad
 --empezando con los spinner que definen cuantos TBs deberia tener cada extremidad
 group "Twist Bones"
 (
  spinner TBUpperArms "UpperArms: " type:#integer range:[0,999999999,3] fieldwidth:40
  spinner TBForeArms "ForeArms: " type:#integer range:[0,999999999,3] fieldwidth:40
  spinner TBThighs "Thighs: " type:#integer range:[0,999999999,3] fieldwidth:40
  spinner TBCalves "Calves: " type:#integer range:[0,999999999,3] fieldwidth:40
 )
 --boton para crear los TBs
 button TBSet "Set TwisBones"
 on TBSet pressed do --evento que se ejecuta cuando opriman el boton
 (
  n=#(TBUpperArms.value,TBForeArms.value,TBThighs.value,TBCalves.value) --el arreglo que dice la cantidad de TBs por cada extremidad
  undo on TBSetFunction n -- llamado a la funcion
 )
)

createDialog TBPersiana
)