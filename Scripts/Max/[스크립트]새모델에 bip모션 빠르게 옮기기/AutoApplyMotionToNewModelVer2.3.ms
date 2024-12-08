
try (destroydialog ContainerRollOut ) catch ()
rollout ContainerRollOut "Auto Apply Motion To New Model Ver2"
(
	--GroupBox 'SimpleAppy' "SimpleAppy" pos:[5,10] width:510 height:180
	dotNetControl _SimpleDrop "label" pos:[30,30] width:470 height:140
	--dotNetControl _SimpleDrop "picturebox" pos:[20,10] width:490 height:180
	
	--GroupBox 'FilesAppy' "FilesAppy" pos:[5,220] width:515 height:370
	button		_AddFiles "AddFiles" pos:[100,240] width:100
	button		_RemoveFiles "RemoveFiles" pos:[215,240] width:100
	button		_ResetList "ResetList" pos:[330,240] width:100
	dotNetControl _FileList "System.Windows.Forms.ListView" width:500 height:200
	edittext	_NewModelFile "NewModelFile" fieldWidth:370 readOnly:false across:2
	button		_NewModelFileOpen "Open" align:#right
	checkbox	_InPlaceModeOn "InPlaceModeOn" checked:false
	checkbox	_CaptureImageOn "CaptureImageOn" checked:false
	--checkbox	_RootStartCheck "RootStartCheck" pos:[100,500] checked:false
	--checkbox	_RootEndCheck "RootEndCheck" pos:[100,520] checked:false
	--checkbox	_SourceStartCheck "SourceStartCheck" pos:[100,560] checked:false
	button		_ApplyMotion "ApplyMotion" width:150 height:30
	progressbar	_ApplyProgressBar color:(color 20 150 240) height:20
	
	fn GetBipBoneFunc biepdName =
	(
		tempBiepdName = "Bip001 " + biepdName
		findBipe = getNodeByName tempBiepdName
		
		if findBipe == undefined do
		(
			tempBiepdName = "Bip01 " + biepdName
			findBipe = getNodeByName tempBiepdName
		)
		
		findBipe
	)

	fn SelectBipBoneFunc =
	(
		if $bip001 == undefined then
			select $bip01
		else
			select $bip001
	)
	
	fn UpdateRemoveFilesButtonState =
	(
		_RemoveFiles.enabled = _FileList.selecteditems.count > 0
	)
	fn UpdateResetListButtonState =
	(
		_ResetList.enabled = _FileList.items.count > 0
	)
	
	fn ListInit =
	(
		_FileList.HeaderStyle = _FileList.HeaderStyle.Nonclickable	-- Flattens the headers a bit (although they're still somewhat 3D) and keeps them from being clickable   
		_FileList.BorderStyle = _FileList.BorderStyle.FixedSingle -- make the border a flat solid color instead of the Windows 3D look
		_FileList.HideSelection = false -- When this ListView loses the focus, it will still show what's selected
		_FileList.view = (dotNetClass "system.windows.forms.view").details
		_FileList.FullRowSelect = true	-- When item is clicked, all columns in that item are selected
		_FileList.GridLines = false-- turn off the grid lines
		_FileList.MultiSelect = true
		_FileList.backColor = _FileList.backColor.FromArgb 225 225 225 -- Soften the background intensity a bit
		
		_FileList.Columns.add "FileName" 150
		_FileList.Columns.add "FilePath" 350
		
		--cb = ((colorman.getColor #background)*255+20) as colorman
		--_FileList.BackColor = (dotNetClass "System.Drawing.Color").fromARGB cb.r cb.g cb.backcolor
		--cf = ((colorman.getColor #text)*255+30) as colorman
		--_FileList.ForceColor = (dotNetClass "System.Color").fromARGB cf.r cf.g cf.backcolor
		
		--_OpenFiles.drawMode = _OpenFiles.DrawMode.OwnerDrawFixed
		--_OpenFiles.backcolor = lbBackColor
		--_FileList.SelectionMode = (dotNetClass "System.Windows.Forms.SelectionMode").MultiSimple
		--_FileList.Items.AddRange ListItems
		
		UpdateRemoveFilesButtonState()
		UpdateResetListButtonState()
	)
	
	fn GetFileName allPath =
	(
		fileName = allPath
		findIndex = 0
		while findIndex != undefined do
		(
			findIndex = findString fileName "\\"
			if findIndex != undefined then
			(
				fileName = subString fileName (findIndex+1) -1
			)
		)
		
		return fileName
	)
	
	fn GetFilePath allPath fileName =
	(
		filePath = ""
		findIndex = findString allPath fileName
		if findIndex != undefined then
		(
			filePath = replace allPath findIndex fileName.count ""
		)
		
		return filePath
	)
	
	fn AddFile fileNames  =
	(
		all_Files = #()
		for i=1 to fileNames.count do
		(
			fileData = fileNames[i]
			fileName = GetFileName fileData
			filePath = GetFilePath fileData fileName
			
			listItem = dotNetObject "System.Windows.Forms.ListViewItem" fileName
			listItem.subitems.add filePath
			append all_Files listItem
		)
		
		_FileList.items.addRange all_Files
		--_FileList.width = AutoResizeColumn _FileList columns:1
		_FileList.Update()
		UpdateResetListButtonState()
		
		--join ListOfMaxFiles theDialog.fileNames --the selected filenames will be returned as an array
		--mlbMaxFiles.items = ListOfMaxFiles
		--number_of_files = mlbMaxFiles.items.count
		--lbNumberOfFiles.text = "All files"
	)
	
	on ContainerRollOut open do
	(
		ListInit()
		
		_FileList.allowDrop = true
		
		_SimpleDrop.allowDrop = true
		_SimpleDrop.text = "Simple Apply\nDrag And Drop Max File"
		_SimpleDrop.textalign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter
		--_SimpleDrop.size = dotNetObject "system.drawing.size" 516 64
		
	)
	
	on _SimpleDrop DragOver sender e do 
	(
		e.Effect = if e.data.ContainsFileDropList() then e.Effect.Move else e.Effect.None
	)
	
	fn GetParentPath targetObj pathValue =
	(
		parentPath = pathValue
		
		if targetObj != undefined do
		(
			parentPath += targetObj.name
			parentPath += "."
			
			parentPath = GetParentPath targetObj.parent parentPath
		)
		
		parentPath
	)
	
	fn GetNotBipedChildBoneCheckKey parentObj &selectChilds =
	(
		for bipChild in parentObj.children do 
		(
			if classof bipChild != Biped_Object do
			(
				posNumKey = numKeys bipChild.position.controller
				rotNumKey = numKeys bipChild.rotation.controller
				scaleNumKey = numKeys bipChild.scale.controller
				
				haveKey = posNumKey > 0 or  rotNumKey > 0 or scaleNumKey > 0
				
				append selectChilds #(bipChild, bipChild.name, GetParentPath bipChild "", haveKey)
				
				if bipChild.children.count > 0 do
				(
					GetNotBipedChildBoneCheckKey bipChild &selectChilds
				)
			)
		)
	)
	
	fn CheckNotBipedChildBoneCheckKey parentObj &selectChilds &selectChildDatas =
	(
		for childData in selectChildDatas do
		(
			for bipChild in parentObj.children do
			(
				if classof bipChild != Biped_Object do
				(
					if bipChild.name == childData[2] and GetParentPath bipChild "" == childData[3] do
					(
						appendIfUnique selectChilds bipChild
					)
					
					if bipChild.children.count > 0 do
					(
						CheckNotBipedChildBoneCheckKey bipChild &selectChilds &selectChildDatas
					)
				)
			)
		)
	)
	
	fn ApplyMotionProcess filePath fileName destFile &deleteFileNamePath =
	(
		loadMaxFile (filePath + fileName) useFileUnits:true quiet:true
						
		-- get start, end time
		sourceStartTime = animationRange.start
		sourceEndTime = animationRange.end
		
		-- save bip file
		SelectBipBoneFunc()
		selectBipBone = biped.getNode $ #horizontal
		tempfigureMode = selectBipBone.controller.figureMode
		biped.setCurrentLayer selectBipBone.controller 0
		selectBipBone.controller.figureMode = false
		sourceBipFileNamePath = (filePath + "tempBip.bip")
		bipSaveOK = biped.SaveBipFile selectBipBone.controller sourceBipFileNamePath
		selectBipBone.controller.figureMode = tempfigureMode
		
		inplacemodeType = -1
		if selectBipBone.controller.inplacemode == true then
		(
			inplacemodeType = 0
		)
		else if selectBipBone.controller.inplacexmode == true then
		(
			inplacemodeType = 1
		)
		else if selectBipBone.controller.inplaceymode == true then
		(
			inplacemodeType = 2
		)
		
		if bipSaveOK == true then
		(
			appendIfUnique deleteFileNamePath sourceBipFileNamePath
			
			SelectBipBoneFunc()
			
			-- select child (not biped, have animation key)
			selectChildDatas = #()
			GetNotBipedChildBoneCheckKey $ &selectChildDatas
			
			if selectChildDatas.count > 0 do
			(
				-- source lock, inherit
				for childData in selectChildDatas do
				(
					sourceLockFlags = getTransformLockFlags childData[1]
					sourceInheritanceFlags = getInheritanceFlags childData[1]
					append childData #(sourceLockFlags, sourceInheritanceFlags)
					
					-- save animation
					if childData[4] == true do
					(
						sourceAnimationFileNamePath = (filePath + childData[2] + ".xaf")
						LoadSaveAnimation.saveAnimation sourceAnimationFileNamePath childData[1] #("") #("") animatedTracks:true includeConstraints:true
						appendIfUnique deleteFileNamePath sourceAnimationFileNamePath
					)
				)
			)
		
			-- destFile Process
			loadMaxFile destFile useFileUnits:true quiet:true
			
			-- load bip file
			SelectBipBoneFunc()
			selectBipBone = biped.getNode $ #horizontal
			selectBipBone.controller.figuremode = false
			biped.loadBipFile selectBipBone.controller sourceBipFileNamePath
			select selectBipBone
			
			-- select last layer
			--layerIndex = biped.numLayers selectBipBone.controller
			--biped.setCurrentLayer selectBipBone.controller layerIndex

			-- set start, end time
			animationRange = interval sourceStartTime sourceEndTime
			
			-- check same child
			if selectChildDatas.count > 0 do
			(
				SelectBipBoneFunc()
				
				selectChilds = #()
				CheckNotBipedChildBoneCheckKey $ &selectChilds &selectChildDatas
				
				--if selectChildDatas.count == selectChilds.count do
				(
					-- set lock, inherit
					for childData in selectChildDatas do
					(
						childnode = getNodeByName childData[2]
						if childnode != undefined do
						(
							setTransformLockFlags childnode childData[5][1]
							setInheritanceFlags childnode childData[5][2]
							
							if childData[4] == true then
							(
								-- load animation (Absolute(true) == relative(false), Replace(true) == insert(false)
								sourceAnimationFileNamePath = (filePath + childData[2] + ".xaf")
								LoadSaveAnimation.loadAnimation	sourceAnimationFileNamePath childnode relative:false insert:false
							)
							else
							(
								deletekeys childnode.controller #allkeys
							)
						)
					)
				)
			)
			
			if _InPlaceModeOn.checked == true do
			(
				case inplacemodeType of
				(
					0: $.controller.inplacemode = true
					1: $.controller.inplacexmode = true
					2: $.controller.inplaceymode = true
					default:
					(
						$.controller.inplacemode = false
						$.controller.inplacexmode = false
						$.controller.inplaceymode = false
					)
				)
			)
		)
		else
		(
			print ("Bip File save error : " + sourceBipFileNamePath)
		)
		
		bipSaveOK
	)
	
	on _SimpleDrop DragDrop sender e do 
	(
		if e.data.ContainsFileDropList() do
		(
			data = e.data.GetFileDropList()
			
			if data.count == 1 do
			(
				files = for k=0 to data.count-1 collect data.item[k]
				deleteFileNamePath = #()
				failError = ""
		
				for f in files where doesFileExist f do 
				(
					if isMaxFile f == true then
					(
						destFile = maxFilePath + maxFileName
						
						fileName = GetFileName f
						filePath = GetFilePath f fileName
						
						ApplyMotionProcess filePath fileName destFile &deleteFileNamePath
					)
					else
					(
						print "it's not max file"
					)
				)
				
				if deleteFileNamePath.count > 0 do
				(
					for delete in deleteFileNamePath do
					(
						deleteFile delete
					)
				)
			)
		)
 
	)
	
	on _FileList MouseClick sender args do
	(
		UpdateRemoveFilesButtonState()
	)
	
	on _FileList DragOver sender e do (
 
		e.Effect = if e.data.ContainsFileDropList() then e.Effect.Move else e.Effect.None
 
	)
	on _FileList DragDrop sender e do (
 
		if e.data.ContainsFileDropList() do (
			fileNames = #()
			
			data = e.data.GetFileDropList()
			files = for k=0 to data.count-1 collect data.item[k]
 
			for f in files where doesFileExist f do (
				append fileNames f
			)
			
			AddFile fileNames
		)
	)
	
	fn AutoResizeColumn listView columns: =
	(
		vScrollWidth = 21
		for i = 0 to columns-1 do
		(
			listView.AutoResizeColumn i (dotNetClass "ColumnHeaderAutoResizeStyle").ColumnContent
			vScrollWidth += listView.Columns.Item[i].Width
		);vScrollWidth
	)
	
	fn OpenFileDialog title filter multiselect =
	(
		theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" --create a OpenFileDialog 
		theDialog.title = title --set the title
		theDialog.Multiselect = multiselect --allow multiple files to be selected
		theDialog.Filter = filter --specify the filter
		theDialog.FilterIndex = 1 --set the filter drop-down list to All Files
		result = theDialog.showDialog() --display the dialog, get result into variable
		result.ToString() --when closed, convert the result to string
		result.Equals result.OK --returns TRUE if OK was pressed, FALSE otherwise
		result.Equals result.Cancel --returns TRUE if Cancel was pressed, FALSE otherwise
		
		return theDialog
	)
	
	on _AddFiles pressed do
	(
		theDialog = OpenFileDialog "Select One Or More Files" "MAX Files (*.max)|*.max" true
		AddFile theDialog.fileNames
	)
	
	on _RemoveFiles pressed do
	(
		if _FileList.selecteditems.count > 0 then
		(
			for i = _FileList.selecteditems.count to 1 by -1 do
			(
				_FileList.items.Remove(_FileList.selecteditems.item[i-1])
			)
		)
		else
		(
			MessageBox "Select At least one from the list"
		)
	)
	
	on _ResetList pressed do
	(
		_FileList.clear()
		ListInit()
	)
	
	on _NewModelFileOpen pressed do
	(
		theDialog = OpenFileDialog "Select New Model Files" "MAX Files (*.max)|*.max" false
		
		for i=1 to theDialog.fileNames.count do
		(
			_NewModelFile.text = theDialog.fileNames[i]
		)
	)
	
	on _ApplyMotion pressed do
	(
		_ApplyProgressBar.value = 0
		loopCheck = _FileList.items.count - 1
		deleteFileNamePath = #()
		failFileName = #()
		for i=0 to loopCheck do
		(
			-- OldFile
			filePath = _FileList.items.item[i].subItems.item[1].text
			fileName = _FileList.items.item[i].subItems.item[0].text
			
			if ApplyMotionProcess filePath fileName _NewModelFile.text &deleteFileNamePath == true then
			(
				SelectBipBoneFunc()
				selectBipBone = biped.getNode $ #horizontal
				
				if _CaptureImageOn.checked == true do
				(
					hideByCategory.all()
					hideByCategory.geometry = false
					
					viewport.setType #view_front
					actionMan.executeAction 0 "40021"  -- Selection: Select All
					actionMan.executeAction 0 "310"
					clearSelection()
					redrawViews()
					
					captureImagePath = (filePath + "Capture Image")
					directory = getDirectories captureImagePath
					if directory.count == 0 do
					(
						makedir captureImagePath
					)

					img = gw.getViewportDib()
					
					imgFileName = fileName
					tempIndex = findString imgFileName ".max"
					if tempIndex != undefined do
					(
						imgFileName = substring imgFileName 1 (tempIndex - 1)
					)
					
					img.filename = captureImagePath + "\\" + imgFileName + ".jpg"
					save img
				)
				
				saveMaxFile (filePath+fileName) quiet:true
			)
			else
			(
				appendIfUnique failFileName (filePath + fileName)
			)
			
			_ApplyProgressBar.value = 100.*(i+1) / (loopCheck+1)
		)
		
		for delete in deleteFileNamePath do
		(
			deleteFile delete
		)
		
		message = "[Work Finish]\n\n"
		if failFileName.count > 0 then
		(
			message = message + "<Fail FileName>\n"
			for failFile in failFileName do
			(
				message = message + failFile + "\n"
			)
		)
		
		MessageBox message
	)
)

createDialog ContainerRollOut 530 600