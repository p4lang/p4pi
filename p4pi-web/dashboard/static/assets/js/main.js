function getCookie(name) {
    var cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        var cookies = document.cookie.split(';');
        for (var i = 0; i < cookies.length; i++) {
            var cookie = cookies[i].trim();
            // Does this cookie string begin with the name we want?
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

const setUpCsrfToken = () => {
    const csrftoken = getCookie('csrftoken');
    return (url, data) => {
        return fetch(url, {
            method: 'POST',
            credentials: 'include',
            cache: 'no-cache',
            referrerPolicy: 'no-referrer',
            headers: new Headers({
                'X-CSRFToken': csrftoken,
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'X-Requested-With': 'XMLHttpRequest'
            }),
            body: JSON.stringify(data)
        })
    }
}

const sendPostRequest = setUpCsrfToken();