({
    tabSelectHandler: function (component, event, helper) {
        const selectedTab = event.getParam('id');

        if (selectedTab === 'person') {
            component.set('v.headerTitle', 'Person View');
        } else {
            component.set('v.headerTitle', 'Location View');
        }
        component.set('v.scope', selectedTab);

        const healthHeaderComp = component.find('health-header');
        healthHeaderComp.fetchCount();
    }
})
