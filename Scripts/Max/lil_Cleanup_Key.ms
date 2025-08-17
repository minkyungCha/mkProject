
--=========================================================================================
--함수정의 about
--=========================================================================================
--findStep : 문자열에서 특정 문자열을 찾아서 있으면 false, 없으면 true를 반환
--getSelectedBiped : 선택된 오브젝트 중에 바이페드 오브젝트를 찾아서 반환
--collectBipedBones : 바이페드 오브젝트의 하위 본들을 찾아서 리스트에 저장
--getKeyframesToKeep : 바이페드 오브젝트의  키프레임을 찾아서 리스트에 저장
--deleteBipedKey : 바이페드 오브젝트의 특정 시간의 키프레임을 삭제
--addBipedKey : 바이페드 오브젝트의 특정 시간에 키프레임을 추가
--=========================================================================================

fn findStep str keyword =
(
	if findString str keyword != undefined then
		return false
	else
		return true
)
fn getSelectedBiped =
(
	if selection.count != 0 then
	(
		selectedBiped = undefined

		for obj in selection do
		(
			if classOf obj == Biped_Object do
			(
				selectedBiped = obj
				exit
			)
		)

		if selectedBiped == undefined then
		(
			messageBox "Need to select a Biped object!"
			return ""
		)
		else
		(
			return selectedBiped.controller.rootname
		)
	)
	else
	(
		messageBox "No object selected!"
		return ""
	)
)
fn collectBipedBones bipedBone boneList =
(
	if classOf bipedBone == Biped_Object and findStep bipedBone.name "footstep" do append boneList bipedBone
	if bipedBone.children != undefined do
	(
		for child in bipedBone.children do
		(
			collectBipedBones child boneList
		)
	)
)
fn getKeyframesToKeep biped =
(
    keyframesToKeep = #()
    
    -- 각 컨트롤러 가져오기
    turningController = biped.controller.turning.controller
    horizontalController = biped.controller.horizontal.controller
    verticalController = biped.controller.vertical.controller

    startFrame = animationRange.start
    endFrame = animationRange.end

    for i = startFrame to endFrame do
    (
        keyIndexTurn = getKeyIndex turningController i
        keyIndexHorz = getKeyIndex horizontalController i
        keyIndexVert = getKeyIndex verticalController i

        -- 하나라도 키가 있으면 추가
        if keyIndexTurn != 0 or keyIndexHorz != 0 or keyIndexVert != 0 do append keyframesToKeep i
    )

    return keyframesToKeep
)

fn deleteBipedKey bipedBone time =
(
	if bipedBone.name == bipedBone.controller.rootname then
	(
		horizontalController = bipedBone.controller.horizontal.controller
		verticalController = bipedBone.controller.vertical.controller
		hIndex = getKeyIndex horizontalController time
		vIndex = getKeyIndex verticalController time
		if hIndex != 0 do deleteKey horizontalController hIndex
		if vIndex != 0 do deleteKey verticalController vIndex
	)
	else
	(
		boneController = bipedBone.controller
		cIndex = getKeyIndex boneController time
		if cIndex != 0 do deleteKey boneController cIndex
	)
)

fn addBipedKey bipedBone time =
(
	if bipedBone.name == bipedBone.controller.rootname then
	(
		horizontalController = bipedBone.controller.horizontal.controller
		verticalController = bipedBone.controller.vertical.controller
        tueningController = bipedBone.controller.turning.controller
		biped.addNewKey verticalController time
		biped.addNewKey horizontalController time
        biped.addNewKey tueningController time
	)
	else
	(
		try (biped.addNewKey bipedBone.controller time) catch()
	)
)

--=========================================================================================
--함수정의 end
--=========================================================================================


--=========================================================================================
--UI정의
--=========================================================================================

try (destroyDialog bipedKeyToolDialog) catch()
rollout bipedKeyToolDialog "Biped Key Clean Up" width:170 height:63
(
	button btnCleanup "One-click Cleanup" pos:[20,9] width:130 height:30 align:#left
	hyperlink blog "Made by lil_jongyoon" pos:[40,45] width:160 height:20 color:orange address:"https://blog.naver.com/trueb000"


--=========================================================================================
--버튼기능정의
--=========================================================================================
	on btnCleanup pressed do
	(
		bipedRootName = getSelectedBiped()
		if bipedRootName == "" then return 0

		bipedRootName = "$'" + bipedRootName + "'"
		bipedRoot = execute bipedRootName

		bipedBones = #()
		collectBipedBones bipedRoot bipedBones

		if bipedBones.count == 0 then
		(
			messagebox "No valid Biped bones found!"
			return 0
		)

		keyframesToKeep = getKeyframesToKeep bipedRoot

		if keyframesToKeep == undefined or keyframesToKeep.count == 0 then
		(
			messagebox "No keyframes found to process!"
			return 0
		)

		undo on
		(
			for i = 1 to bipedBones.count do
			(
				for j = 1 to keyframesToKeep.count do
				(
					addBipedKey bipedBones[i] keyframesToKeep[j]
				)
			)

			for i = animationRange.end  to animationRange.start  by -1f do
			(
				keepFrame = false
				for j = 1 to keyframesToKeep.count do
				(
					if i == keyframesToKeep[j] do keepFrame = true
				)

				if keepFrame then continue
				else
				(
					for k = 1 to bipedBones.count do
					(
						deleteBipedKey bipedBones[k] i
					)
				)
			)
		)
	)
)

createDialog bipedKeyToolDialog width:170 height:63
