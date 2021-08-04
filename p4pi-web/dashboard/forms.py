from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm
from django import forms
from .utils import get_countries


class AccessPointSettingsForm(forms.Form):
    ssid = forms.CharField(
        label='Service Set Identifier (SSID)',
        widget=forms.TextInput(
            attrs={
                'placeholder': 'p4pi',
                'class': 'form-control'
            }
        ),
        max_length=60
    )
    passphrase = forms.CharField(
        widget=forms.TextInput(
            attrs={
                'placeholder': 'raspberry',
                'class': 'form-control',
            }
        ),
        label="Password"
    )
    channel = forms.DecimalField(
        widget=forms.TextInput(
            attrs={
                'placeholder': '7',
                'class': 'form-control',
            }
        ),
        label="Channel",
        min_value=1,
        max_value=14
    )
    country_code = forms.ChoiceField(
        label='Country Code',
        choices=get_countries(),
        widget=forms.Select(attrs={'class': 'form-control'}),
    )
    static_ip_address = forms.CharField(
        label='Static IP Address',
        widget=forms.TextInput(
            attrs={
                'placeholder': '192.168.0.1/24',
                'class': 'form-control'
            }
        ),
    )
    range_min = forms.CharField(
        label='DHCP Range Start Address',
        widget=forms.TextInput(
            attrs={
                'placeholder': '192.168.0.2',
                'class': 'form-control'
            }
        ),
    )
    range_max = forms.CharField(
        label='DHCP Range End Address',
        widget=forms.TextInput(
            attrs={
                'placeholder': '192.168.0.20',
                'class': 'form-control'
            }
        ),
    )
    lease = forms.CharField(
        label='DHCP Lease',
        widget=forms.TextInput(
            attrs={
                'placeholder': '24h',
                'class': 'form-control'
            }
        ),
    )


class LoginForm(forms.Form):
    username = forms.CharField(
        widget=forms.TextInput(
            attrs={
                "placeholder": "Username",
                "class": "form-control"
            }
        ))
    password = forms.CharField(
        widget=forms.PasswordInput(
            attrs={
                "placeholder": "Password",
                "class": "form-control"
            }
        ))


class SignUpForm(UserCreationForm):
    username = forms.CharField(
        widget=forms.TextInput(
            attrs={
                "placeholder": "Username",
                "class": "form-control"
            }
        ))
    password1 = forms.CharField(
        widget=forms.PasswordInput(
            attrs={
                "placeholder": "Password",
                "class": "form-control"
            }
        ))
    password2 = forms.CharField(
        widget=forms.PasswordInput(
            attrs={
                "placeholder": "Password check",
                "class": "form-control"
            }
        ))

    class Meta:
        model = User
        fields = ('username', 'password1', 'password2')
