angular.module('ponyfm').controller "account-content-tracks", [
	'$scope', '$state', 'taxonomies', '$dialog', 'lightbox'
	($scope, $state, taxonomies, $dialog, lightbox) ->
		$('#coverPreview').load () ->
			$scope.$apply -> $scope.isCoverLoaded = true
			window.alignVertically(this)

		$scope.isCoverLoaded = false
		$scope.selectedTrack = null
		$scope.isDirty = false
		$scope.taxonomies =
			trackTypes: taxonomies.trackTypes
			licenses: taxonomies.licenses
			genres: taxonomies.genres

		$scope.updateIsVocal = () ->
			delete $scope.errors.lyrics if !$scope.edit.is_vocal

		$scope.previewCover = () ->
			return if !$scope.edit.cover
			lightbox.openDataUrl $('#coverPreview').attr 'src'

		$scope.updateTrack = (track) ->
			xhr = new XMLHttpRequest()
			xhr.onload = -> $scope.$apply ->
				if xhr.status != 200
					errors =
						if xhr.getResponseHeader('content-type') == 'application/json'
							$.parseJSON(xhr.responseText).errors
						else
							['There was an unknown error!']

					$scope.errors = {}
					_.each errors, (value, key) -> $scope.errors[key] = value.join ', '
					return

				$scope.selectedTrack.is_published = true
				selectTrack $scope.selectedTrack

			formData = new FormData();
			_.each $scope.edit, (value, name) ->
				if name == 'cover'
					formData.append name, value, value.name
				else
					formData.append name, value

			xhr.open 'POST', '/api/web/tracks/edit/' + $scope.edit.id, true
			xhr.setRequestHeader 'X-Token', pfm.token
			xhr.send formData

		$scope.uploadTrackCover = () ->
			$("#coverImage").trigger 'click'

		$scope.setCoverImage = (input) ->
			$scope.$apply ->
				previewElement = $('#coverPreview')[0]
				file = input.files[0]

				if file.type != 'image/png'
					$scope.errors.cover = 'Cover image must be a png!'
					$scope.isCoverLoaded = false
					$scope.edit.cover = null
					return

				delete $scope.errors.cover
				$scope.isDirty = true
				reader = new FileReader()
				reader.onload = (e) -> previewElement.src = e.target.result
				reader.readAsDataURL file
				$scope.edit.cover = file

		$scope.clearTrackCover = () ->
			$scope.isCoverLoaded = false
			delete $scope.edit.cover

		$scope.filters =
			published: [
				{title: 'Either', query: ''},
				{title: 'Yes', query: 'published=1'},
				{title: 'No', query: 'published=0'}]

			sort: [
				{title: 'Newest to Oldest', query: 'order=created_at,desc'},
				{title: 'Oldest to Newest', query: 'order=created_at,asc'}]

			genres: {}
			trackTypes: {}

		$scope.filter =
			published: $scope.filters.published[0]
			sort: $scope.filters.sort[0]
			genres: {}
			trackTypes: {}

		$scope.titles =
			genres: 'All'
			trackTypes: 'All'

		taxonomies.refresh().done () ->
			for genre in taxonomies.genres
				$scope.filters.genres[genre.id] =
					id: genre.id
					title: genre.name
					query: 'genres[]=' + genre.id
			for type in taxonomies.trackTypes
				$scope.filters.trackTypes[type.id] =
					id: type.id
					title: type.title
					query: 'types[]=' + type.id

		$scope.updateFilter = (type, filter) ->
			$scope.filter[type] = filter
			$scope.refreshList()

		$scope.toggleFilter = (type, id) ->
			if !$scope.filter[type][id]
				$scope.filter[type][id] = $scope.filters[type][id]
			else
				delete $scope.filter[type][id]

			length = _.keys($scope.filter[type]).length
			if length == 1
				$scope.titles[type] = _.map($scope.filter[type], (f) -> f.title).join ', '
			else if length > 1
				$scope.titles[type] = length + ' selected'
			else
				$scope.titles[type] = 'All'

			$scope.refreshList()

		$scope.refreshList = () ->
			parts = [$scope.filter.sort.query, $scope.filter.published.query]
			_.each $scope.filter.genres, (g) -> parts.push g.query
			_.each $scope.filter.trackTypes, (g) -> parts.push g.query
			query = parts.join '&'
			$.getJSON('/api/web/tracks/owned?' + query).done (tracks) -> $scope.$apply -> showTracks tracks

		tracksDb = {}

		showTracks = (tracks) ->
			tracksDb = {}
			$scope.tracks = tracks
			tracksDb[track.id] = track for track in tracks

		selectTrack = (t) ->
			$scope.selectedTrack = t
			$scope.isCoverLoaded = false
			return if !t
			$.getJSON('/api/web/tracks/edit/' + t.id)
				.done (track) -> $scope.$apply ->
					$scope.isDirty = false
					$scope.errors = {}
					$scope.edit =
						id: track.id
						title: track.title
						description: track.description
						lyrics: track.lyrics
						is_explicit: track.is_explicit
						is_downloadable: track.is_downloadable
						is_vocal: track.is_vocal
						license_id: track.license_id
						genre_id: track.genre_id
						track_type_id: track.track_type_id
						released_at: if track.released_at then track.released_at.date else ''

		$scope.touchModel = -> $scope.isDirty = true

		$.getJSON('/api/web/tracks/owned?order=created_at,desc').done (tracks) -> $scope.$apply ->
			showTracks tracks
			if $state.params.track_id
				selectTrack tracksDb[$state.params.track_id]

		$scope.selectTrack = (track) -> $scope.selectedTrack = track
		$scope.deleteTrack = (track) ->
			$dialog.messageBox('Delete ' + track.title, 'Are you sure you want to delete "' + track.title + '"? This cannot be undone.', [
				{result: 'ok', label: 'Yes', cssClass: 'btn-danger'}, {result: 'cancel', label: 'No', cssClass: 'btn-primary'}
			]).open().then (res) ->
				return if res == 'cancel'
				selectTrack null if track == $scope.selectedTrack
				$.post('/api/web/tracks/delete/' + track.id, {_token: window.pfm.token})
					.then ->
						$scope.refreshList()

		$scope.$on '$stateChangeSuccess', () ->
			if $state.params.track_id
				selectTrack tracksDb[$state.params.track_id]
			else
				selectTrack null

		$scope.$on '$stateChangeStart', (e) ->
			return if $scope.selectedTrack == null || !$scope.isDirty
			e.preventDefault() if !confirm('Are you sure you want to leave this page without saving your changes?')
]