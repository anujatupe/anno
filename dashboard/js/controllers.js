var Dashboard = angular.module('Dashboard', ['DashboardConstantsModule']);

Dashboard.controller('Login', function($scope, $http, $window, $location, DashboardConstants) {
	$scope.apiRoot = DashboardConstants.apiRoot[DashboardConstants.serverURLKey];
	$scope.endpointData = DashboardConstants.endpointUrl["account.dashboard.authenticate"];
    $scope.url = $scope.apiRoot + "/" + $scope.endpointData.root + "/" + DashboardConstants.endpointVersion + "/" + $scope.endpointData.path;

	$scope.authenticate_dashboard = function() {
		$scope.params = {
			"user_email" : $scope.email,
			"team_key" : $scope.teamkey,
			"password" : $scope.password
		};

		$scope.req = {
			method: $scope.endpointData.method,
			url: $scope.url,
			headers: { 'Content-Type': 'application/json' },
			data: $scope.params,
		};

		$http($scope.req).success(function(data, status) {
			$scope.data = data;
			$window.localStorage['user'] = angular.toJson(data);
			if ($scope.data.authenticated) {
				$window.location.href = $location.absUrl().replace('login.html', 'index.html');
			}
		});
	};
});

Dashboard.controller('Feed', function($scope, $window) {
	console.log(angular.fromJson($window.localStorage.user));
});